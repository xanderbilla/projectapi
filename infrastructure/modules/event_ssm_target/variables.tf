variable "ec2_instance_ids" {
  description = "List of EC2 instance IDs to attach to the target group"
  type        = list(string)
}

variable "cloudwatch_event_rule_name" {
  description = "Name of the AWS CloudWatch Event Rule"
  type        = string
}

variable "ssm_document_arn" {
  description = "ARN of the AWS SSM Document"
  type        = string
}

variable "eventbridge_ssm_role_arn" {
  description = "ARN of the IAM role that EventBridge will assume to invoke the SSM document"
  type        = string
}
