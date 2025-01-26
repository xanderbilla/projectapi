output "log_group_arn" {
  value       = aws_cloudwatch_log_group.prod_log_group.arn
  description = "The ARN of the CloudWatch Log Group"
}

output "log_stream_arn" {
  value       = aws_cloudwatch_log_stream.prod_log_stream.arn
  description = "The ARN of the CloudWatch Log Stream"
}
