variable "project_name" {
  description = "Name of the project to tag resources"
  type        = string
}

variable "ami_id" {
  description = "AMI ID to use for EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "ec2_role_name" {
  description = "IAM role name to attach to EC2 instances"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs to associate with EC2 instances"
  type        = list(string)
}