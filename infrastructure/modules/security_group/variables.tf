variable "project_name" {
  description = "Name of the project to tag resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed to access EC2 instances over SSH (port 22)"
  type        = string
  default     = "0.0.0.0/0"
}
