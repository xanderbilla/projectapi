provider "aws" {
    region = "ap-south-1"
}

terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket-myproject"   # Your S3 bucket name
    key            = "terraform/state/terraform.tfstate"  # Path to store the state file in the bucket
    region         = "ap-south-1"  # Your AWS region
    dynamodb_table = "terraform-locks"  # (Optional) DynamoDB table for state locking
    encrypt        = true  # Encrypt state file at rest (recommended)
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
