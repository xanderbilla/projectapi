variable "role_name" {
  description = "Name of the IAM role for EventBridge to invoke SSM commands"
  type        = string
  default     = "eventbridge-ssm-role"
}

variable "policy_name" {
  description = "Name of the policy granting EventBridge permission to use SSM"
  type        = string
  default     = "eventbridge-ssm-policy"
}

