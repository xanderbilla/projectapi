resource "aws_instance" "ec2_instance" {
  count             = 2
  ami               = var.ami_id
  instance_type     = var.instance_type
  subnet_id         = element(var.public_subnet_ids, count.index)
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  vpc_security_group_ids = var.security_group_ids

  # User Data Script (can be customized)
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
    Name = "${var.project_name}-server-${count.index + 1}"
  }
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "projectapi-ec2-instance-profile"
  role = var.ec2_role_name
}

