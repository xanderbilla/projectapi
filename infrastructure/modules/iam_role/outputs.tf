output "ec2_role_name" {
  value       = aws_iam_role.ec2_role.name
  description = "The name of the IAM role for EC2"
}

output "ec2_role_arn" {
  value       = aws_iam_role.ec2_role.arn
  description = "The ARN of the IAM role for EC2"
}
