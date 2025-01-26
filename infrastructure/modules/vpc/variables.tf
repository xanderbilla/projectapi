# VPC Variables
variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones to distribute the subnets"
  type        = list(string)
}

variable "project_name" {
  description = "Name of the project to tag resources"
  type        = string
}
