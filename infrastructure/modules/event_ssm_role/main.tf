resource "aws_iam_role" "eventbridge_ssm_role" {
  name               = var.role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "eventbridge_ssm_policy" {
  name        = var.policy_name
  description = "Policy to allow EventBridge to send commands to SSM"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ssm:SendCommand"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eventbridge_ssm_role_policy_attachment" {
  role       = aws_iam_role.eventbridge_ssm_role.name
  policy_arn = aws_iam_policy.eventbridge_ssm_policy.arn
}
