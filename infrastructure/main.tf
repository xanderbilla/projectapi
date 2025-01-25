variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

provider "aws" {
    region = var.region
}

data "aws_caller_identity" "current" {}

terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket-myproject"
    key            = "terraform/state/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

resource "aws_vpc" "projectapi_vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "projectapi-vpc"
    }
}

resource "aws_subnet" "projectapi_public_subnet_1" {
    vpc_id            = aws_vpc.projectapi_vpc.id
    cidr_block        = "10.0.1.0/24"
    availability_zone = "ap-south-1a"
    map_public_ip_on_launch = true
    tags = {
        Name = "projectapi-public-subnet-1"
    }
}

resource "aws_subnet" "projectapi_public_subnet_2" {
    vpc_id            = aws_vpc.projectapi_vpc.id
    cidr_block        = "10.0.2.0/24"
    availability_zone = "ap-south-1b"
    map_public_ip_on_launch = true
    tags = {
        Name = "projectapi-public-subnet-2"
    }
}

resource "aws_internet_gateway" "projectapi_igw" {
    vpc_id = aws_vpc.projectapi_vpc.id
    tags = {
        Name = "projectapi-igw"
    }
}

resource "aws_route_table" "projectapi_route_table" {
    vpc_id = aws_vpc.projectapi_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.projectapi_igw.id
    }

    tags = {
        Name = "projectapi-route-table"
    }
}

resource "aws_route_table_association" "projectapi_subnet_1_association" {
    subnet_id      = aws_subnet.projectapi_public_subnet_1.id
    route_table_id = aws_route_table.projectapi_route_table.id
}

resource "aws_route_table_association" "projectapi_subnet_2_association" {
    subnet_id      = aws_subnet.projectapi_public_subnet_2.id
    route_table_id = aws_route_table.projectapi_route_table.id
}

resource "aws_security_group" "projectapi_alb_sg" {
    vpc_id = aws_vpc.projectapi_vpc.id
    name   = "projectapi-alb-sg"
    description = "Security group for ALB"

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "projectapi-alb-sg"
    }
}

resource "aws_security_group" "projectapi_ec2_sg" {
    vpc_id = aws_vpc.projectapi_vpc.id
    name   = "projectapi-ec2-sg"
    description = "Security group for EC2 instances"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "projectapi-ec2-sg"
    }
}

resource "aws_iam_role" "projectapi_ec2_role" {
    name = "projectapi-ec2-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "ec2.amazonaws.com"
                }
            }
        ]
    })

    tags = {
        Name = "projectapi-ec2-role"
    }
}

resource "aws_iam_role_policy_attachment" "projectapi_ec2_ecr_readonly" {
    role       = aws_iam_role.projectapi_ec2_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Attach AmazonSSMManagedInstanceCore policy to the EC2 role
resource "aws_iam_role_policy_attachment" "projectapi_ec2_ssm" {
    role       = aws_iam_role.projectapi_ec2_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "projectapi_secrets_manager_policy" {
    name        = "projectapi-secrets-manager-policy"
    description = "Policy for Secrets Manager access"

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = [
                    "secretsmanager:GetSecretValue",
                    "secretsmanager:DescribeSecret"
                ]
                Effect   = "Allow"
                Resource = "*"
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "projectapi_secrets_manager_access" {
    role       = aws_iam_role.projectapi_ec2_role.name
    policy_arn = aws_iam_policy.projectapi_secrets_manager_policy.arn
}

resource "aws_instance" "projectapi_ec2" {
    ami           = "ami-0d2614eafc1b0e4d2"
    instance_type = "t2.micro"
    subnet_id     = aws_subnet.projectapi_public_subnet_1.id
    security_groups = [aws_security_group.projectapi_ec2_sg.id]
    associate_public_ip_address = true

    iam_instance_profile = aws_iam_instance_profile.projectapi_ec2_instance_profile.name

    user_data = <<-EOF
                #!/bin/bash
                sudo yum update -y
                sudo dnf install docker -y
                sudo dnf install python -y
                sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
                sudo systemctl enable amazon-ssm-agent
                sudo systemctl start amazon-ssm-agent
                sudo systemctl start docker
                caller=$(aws sts get-caller-identity --query 'Account' --output text)
                aws ecr get-login-password --region ap-south-1 | sudo docker login --username AWS --password-stdin $caller.dkr.ecr.ap-south-1.amazonaws.com
                sudo docker pull $caller.dkr.ecr.ap-south-1.amazonaws.com/myprojectapi:latest
                sudo docker tag $caller.dkr.ecr.ap-south-1.amazonaws.com/myprojectapi my-spring-image
                sudo docker rmi -f $caller.dkr.ecr.ap-south-1.amazonaws.com/myprojectapi:latest
                secret=$(aws secretsmanager get-secret-value --secret-id mongo/connection-url --query 'SecretString' --output text | python -c "import json, sys; print(json.load(sys.stdin)['MONGO_URI'])")
                sudo docker run -d -p 8080:8080 -e MONGO_URI=$secret --name spring-app my-spring-image
                EOF

    tags = {
        Name = "projectapi-ec2"
    }
}

resource "aws_iam_instance_profile" "projectapi_ec2_instance_profile" {
    name = "projectapi-ec2-instance-profile"
    role = aws_iam_role.projectapi_ec2_role.name
}

resource "aws_lb" "projectapi_alb" {
    name               = "projectapi-alb"
    internal           = false
    load_balancer_type = "application"
    security_groups    = [aws_security_group.projectapi_alb_sg.id]
    subnets            = [aws_subnet.projectapi_public_subnet_1.id, aws_subnet.projectapi_public_subnet_2.id]

    tags = {
        Name = "projectapi-alb"
    }
}

resource "aws_lb_target_group" "projectapi_tg" {
    name     = "projectapi-tg"
    port     = 8080
    protocol = "HTTP"
    vpc_id   = aws_vpc.projectapi_vpc.id

    health_check {
        path                = "/health"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
        matcher             = "200"
    }

    tags = {
        Name = "projectapi-tg"
    }
}

resource "aws_lb_listener" "projectapi_listener" {
    load_balancer_arn = aws_lb.projectapi_alb.arn
    port              = "80"
    protocol          = "HTTP"

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.projectapi_tg.arn
    }
}

resource "aws_lb_target_group_attachment" "projectapi_tg_attachment" {
    target_group_arn = aws_lb_target_group.projectapi_tg.arn
    target_id        = aws_instance.projectapi_ec2.id
    port             = 8080
}

resource "aws_cloudfront_origin_access_identity" "projectapi_oai" {
    comment = "OAI for projectapi"
}

resource "aws_cloudfront_distribution" "projectapi_distribution" {
    origin {
        domain_name = aws_lb.projectapi_alb.dns_name
        origin_id   = "projectapi-alb"

        custom_origin_config {
            http_port              = 80
            https_port             = 443
            origin_protocol_policy = "http-only"
            origin_ssl_protocols   = ["TLSv1.2"]
        }
    }

    enabled             = true
    is_ipv6_enabled     = true
    comment             = "CloudFront distribution for projectapi"
    default_root_object = ""

    default_cache_behavior {
        allowed_methods  = ["GET", "HEAD", "OPTIONS"]
        cached_methods   = ["GET", "HEAD"]
        target_origin_id = "projectapi-alb"

        forwarded_values {
            query_string = false
            cookies {
                forward = "none"
            }
        }

        viewer_protocol_policy = "redirect-to-https"
        min_ttl                = 0
        default_ttl            = 3600
        max_ttl                = 86400
    }

    price_class = "PriceClass_100"

    restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }

    viewer_certificate {
        cloudfront_default_certificate = true
    }

    tags = {
        Name = "projectapi-distribution"
    }
}

# EventBridge Rule to Trigger on ECR Image Push
resource "aws_cloudwatch_event_rule" "ecr_image_push_rule" {
  name        = "ecr-image-push-rule"
  description = "Triggered when a new image is pushed to ECR"
  event_pattern = <<EOT
  {
    "source": ["aws.ecr"],
    "detail-type": ["ECR Image Action"],
    "detail": {
      "action-type": ["PUSH"],
      "result": ["SUCCESS"],
      "repository-name": ["myprojectapi"],
      "image-tag": ["latest"]
    }
  }
  EOT
}

resource "aws_ssm_document" "run_command" {
    name          = "RunShellScript"
    document_type = "Command"

    content = jsonencode({
        schemaVersion = "2.2"
        description   = "Run shell script on EC2"
        mainSteps = [
            {
                action = "aws:runShellScript"
                name   = "runShellScript"
                inputs = {
                    runCommand = [
                        "sudo docker stop spring-app || true",
                        "sudo docker rm -f spring-app || true",
                        "sudo docker rmi -f my-spring-image || true",
                        "caller=$(aws sts get-caller-identity --query 'Account' --output text)",
                        "aws ecr get-login-password --region ap-south-1 | sudo docker login --username AWS --password-stdin $caller.dkr.ecr.ap-south-1.amazonaws.com",
                        "sudo docker pull $caller.dkr.ecr.ap-south-1.amazonaws.com/myprojectapi:latest",
                        "sudo docker tag $caller.dkr.ecr.ap-south-1.amazonaws.com/myprojectapi my-spring-image",
                        "sudo docker rmi -f $caller.dkr.ecr.ap-south-1.amazonaws.com/myprojectapi:latest",
                        "secret=$(aws secretsmanager get-secret-value --secret-id mongo/connection-url --query 'SecretString' --output text | jq -r .MONGO_URI)",
                        "sudo docker run -d -p 8080:8080 -e MONGO_URI=$secret --name spring-app my-spring-image"
                    ]
                }
            }
        ]
    })
}


resource "aws_iam_role" "eventbridge_ssm_role" {
  name = "eventbridge-ssm-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "eventbridge_ssm_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
  role       = aws_iam_role.eventbridge_ssm_role.name
}

# EventBridge Target to Trigger SSM Run Command
resource "aws_cloudwatch_event_target" "ecr_event_target" {
    rule      = aws_cloudwatch_event_rule.ecr_image_push_rule.name
    target_id = "ssm-command-target"
    # arn     = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:document/projectapi-update-container"
    arn       = aws_ssm_document.run_command.arn

    run_command_targets {
        key    = "InstanceIds"
        values = ["${aws_instance.projectapi_ec2.id}"]
    }

    role_arn = aws_iam_role.eventbridge_ssm_role.arn
}

output "vpc_id" {
    value = aws_vpc.projectapi_vpc.id
}

output "instance_id" {
    value = aws_instance.projectapi_ec2.id
}

output "cloudfront_endpoint" {
    value = "https://${aws_cloudfront_distribution.projectapi_distribution.domain_name}/health"
}

output "alb_endpoint" {
    value = "http://${aws_lb.projectapi_alb.dns_name}/health"
}

output "ec2_public_ip" {
    value = aws_instance.projectapi_ec2.public_ip
}