output "eventbridge_target_arn" {
  value       = aws_cloudwatch_event_target.ssm_run_command_target.arn
  description = "The ARN of the EventBridge target"
}
