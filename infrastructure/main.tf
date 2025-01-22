# Define the AWS provider and region
provider "aws" {
    region = "ap-south-1"
}

# Remote state configuration
terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket-myproject"   # Your S3 bucket name
    key            = "terraform/state/terraform.tfstate"  # Path to store the state file in the bucket
    region         = "ap-south-1"  # Your AWS region
    dynamodb_table = "terraform-locks"  # (Optional) DynamoDB table for state locking
    encrypt        = true  # Encrypt state file at rest (recommended)
  }
}

# Create a VPC
resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "main-vpc"
    }
}

# Create a public subnet in availability zone ap-south-1a
resource "aws_subnet" "public1" {
    vpc_id            = aws_vpc.main.id
    cidr_block        = "10.0.1.0/24"
    availability_zone = "ap-south-1a"

    tags = {
        Name = "public-subnet-1"
    }
}

# Create a public subnet in availability zone ap-south-1b
resource "aws_subnet" "public2" {
    vpc_id            = aws_vpc.main.id
    cidr_block        = "10.0.2.0/24"
    availability_zone = "ap-south-1b"

    tags = {
        Name = "public-subnet-2"
    }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "main-igw"
    }
}

# Create a route table for public subnets
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
    }

    tags = {
        Name = "public-route-table"
    }
}

# Associate the public route table with the first public subnet
resource "aws_route_table_association" "public1" {
    subnet_id      = aws_subnet.public1.id
    route_table_id = aws_route_table.public.id
}

# Associate the public route table with the second public subnet
resource "aws_route_table_association" "public2" {
    subnet_id      = aws_subnet.public2.id
    route_table_id = aws_route_table.public.id
}

# Create a security group for the EC2 instance
resource "aws_security_group" "main" {
    vpc_id = aws_vpc.main.id

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 0
        to_port     = 0
        protocol    = "icmp"
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
        Name = "main-security-group"
    }
}

# Create a security group for the ALB
resource "aws_security_group" "alb" {
    vpc_id = aws_vpc.main.id

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
        Name = "alb-security-group"
    }
}

# Create an EC2 instance
resource "aws_instance" "web" {
    ami                    = "ami-0d2614eafc1b0e4d2" # Amazon Linux 2 AMI (change as needed)
    instance_type          = "t2.micro"
    subnet_id              = aws_subnet.public1.id
    vpc_security_group_ids = [aws_security_group.main.id]
    associate_public_ip_address = true

    iam_instance_profile = aws_iam_instance_profile.ec2_ecr_read_only.name

    user_data = <<-EOF
            #!/bin/bash
            sudo dnf install docker -y
            sudo dnf install python -y
            sudo systemctl start docker
            secret=$(aws secretsmanager get-secret-value --secret-id projectapi/image-repo --query 'SecretString' --output text | python -c "import json, sys; print(json.load(sys.stdin)['REPO'])")
            aws ecr get-login-password --region ap-south-1 | sudo docker login --username AWS --password-stdin 929910138721.dkr.ecr.ap-south-1.amazonaws.com
            sudo docker pull $secret:latest
            sudo docker tag $secret my-spring-image
            sudo docker rmi -f $secret:latest
            secret=$(aws secretsmanager get-secret-value --secret-id mongo/connection-url --query 'SecretString' --output text | python -c "import json, sys; print(json.load(sys.stdin)['MONGO_URI'])")
            sudo docker run -p 8080:8080 -e MONGO_URI=$secret my-spring-image
            EOF

    tags = {
        Name = "web-instance"
    }
}

# Create an IAM role for EC2 to access ECR
resource "aws_iam_role" "ec2_ecr_read_only" {
    name = "EC2ECRReadOnly"

    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Action = "sts:AssumeRole",
                Effect = "Allow",
                Principal = {
                    Service = "ec2.amazonaws.com"
                }
            }
        ]
    })
}

# Attach AmazonEC2ContainerRegistryReadOnly policy to the role
resource "aws_iam_role_policy_attachment" "ecr_read_only_attachment" {
    role       = aws_iam_role.ec2_ecr_read_only.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Create a policy for Secrets Manager access
resource "aws_iam_policy" "secrets_manager_policy" {
    name        = "SecretsManagerAccessPolicy"
    description = "Policy to allow EC2 to access Secrets Manager"
        policy = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Action": ["secretsmanager:GetSecretValue"],
                "Effect": "Allow",
                "Resource": ["arn:aws:secretsmanager:ap-south-1:929910138721:secret:mongo/connection-url-*",
                "arn:aws:secretsmanager:ap-south-1:929910138721:secret:projectapi/image-repo-*"]
            }
        ]
    }
    EOF
}

# Attach SecretsManagerAccessPolicy to the role
resource "aws_iam_role_policy_attachment" "secrets_manager_attachment" {
    role       = aws_iam_role.ec2_ecr_read_only.name
    policy_arn = aws_iam_policy.secrets_manager_policy.arn
}

# Create an instance profile and attach the role
resource "aws_iam_instance_profile" "ec2_ecr_read_only" {
    name = "EC2ECRReadOnly"
    role = aws_iam_role.ec2_ecr_read_only.name
}

# Output the public IP of the EC2 instance
output "instance_public_ip" {
    value = "http://${aws_instance.web.public_ip}:8080/health"
}

# Create an Application Load Balancer (ALB)
resource "aws_lb" "main" {
    name               = "main-lb"
    internal           = false
    load_balancer_type = "application"
    security_groups    = [aws_security_group.alb.id]
    subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]

    tags = {
        Name = "main-lb"
    }
}

# Create a target group for the ALB
resource "aws_lb_target_group" "main" {
    name     = "main-tg"
    port     = 8080
    protocol = "HTTP"
    vpc_id   = aws_vpc.main.id

    health_check {
        path                = "/health"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
        matcher             = "200"
    }

    tags = {
        Name = "main-tg"
    }
}

# Create a listener for the ALB
resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.main.arn
    port              = "80"
    protocol          = "HTTP"

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.main.arn
    }
}

# Attach the EC2 instance to the target group
resource "aws_lb_target_group_attachment" "web" {
    target_group_arn = aws_lb_target_group.main.arn
    target_id        = aws_instance.web.id
    port             = 8080
}

# Output the DNS name of the ALB
output "load_balancer_dns_name" {
    value = "http://${aws_lb.main.dns_name}/api"
}

# Create a CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "projectapi" {
    comment = "Origin Access Identity for ALB"
}

# Create a CloudFront distribution for the ALB
resource "aws_cloudfront_distribution" "projectapi" {
    origin {
        domain_name = aws_lb.main.dns_name
        origin_id   = "alb-origin"

        custom_origin_config {
            http_port              = 80
            https_port             = 443
            origin_protocol_policy = "https-only"
            origin_ssl_protocols   = ["TLSv1.2"]
        }
    }

    enabled             = true
    is_ipv6_enabled     = true
    comment             = "CloudFront distribution for ALB"
    default_root_object = ""

    default_cache_behavior {
        allowed_methods  = ["GET", "HEAD", "OPTIONS"]
        cached_methods   = ["GET", "HEAD"]
        target_origin_id = "alb-origin"

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

# Output the domain name of the CloudFront distribution
output "cloudfront_domain_name" {
    value = aws_cloudfront_distribution.projectapi.domain_name
}