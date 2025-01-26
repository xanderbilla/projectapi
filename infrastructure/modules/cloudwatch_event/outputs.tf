output "event_rule_arn" {
  value       = aws_cloudwatch_event_rule.ecr_image_push_rule.arn
  description = "The ARN of the CloudWatch Event Rule"
}

output "ecr_image_push_rule_name" {
  value       = aws_cloudwatch_event_rule.ecr_image_push_rule.name
  description = "The name of the CloudWatch Event Rule"
}