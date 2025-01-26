variable "log_group_name" {
  description = "Name of the CloudWatch Log Group"
  type        = string
  default     = "/aws/logs/EC2-ALB-CloudFront"
}

variable "log_stream_name" {
  description = "Name of the CloudWatch Log Stream"
  type        = string
  default     = "ec2-alb-cloudfront-stream"
}

variable "log_retention_in_days" {
  description = "The number of days to retain logs in CloudWatch"
  type        = number
  default     = 30
}
