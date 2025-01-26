output "eventbridge_ssm_role_arn" {
  value       = aws_iam_role.eventbridge_ssm_role.arn
  description = "The ARN of the EventBridge SSM role"
}

output "policy_arn" {
  value       = aws_iam_policy.eventbridge_ssm_policy.arn
  description = "The ARN of the EventBridge SSM policy"
}