# Variables for the ALB and Target Group
variable "project_name" {
  description = "Name of the project to tag resources"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID where the ALB and target group will be created"
  type        = string
}

variable "subnet_ids" {
  description = "The list of subnet IDs where the ALB will be placed"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs to associate with ALB"
  type        = list(string)
}

variable "ec2_instance_ids" {
  description = "List of EC2 instance IDs to attach to the target group"
  type        = list(string)
}
