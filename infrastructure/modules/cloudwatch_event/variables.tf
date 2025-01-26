variable "repository_name" {
  description = "The name of the ECR repository to monitor"
  type        = string
}

variable "image_tag" {
  description = "The image tag to filter by (e.g., 'latest')"
  type        = string
  default     = "latest"
}
