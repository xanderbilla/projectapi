variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "target_alb" {
    description = "The DNS name of the ALB"
    type        = string
}

variable "target_origin_id" {
    description = "The name of the origin ID"
    type        = string
}
