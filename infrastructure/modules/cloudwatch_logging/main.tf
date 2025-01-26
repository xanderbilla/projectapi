resource "aws_cloudwatch_log_group" "prod_log_group" {
  name              = var.log_group_name
  retention_in_days = var.log_retention_in_days
}

resource "aws_cloudwatch_log_stream" "prod_log_stream" {
  name           = var.log_stream_name
  log_group_name = aws_cloudwatch_log_group.prod_log_group.name
}

resource "aws_cloudwatch_event_rule" "ec2_event_rule" {
  name        = "EC2-Log-Rule"
  description = "Capture EC2 state change events"
  event_pattern = jsonencode({
    "source": ["aws.ec2"]
  })
}

resource "aws_cloudwatch_event_rule" "alb_event_rule" {
  name        = "ALB-Log-Rule"
  description = "Capture ALB access logs"
  event_pattern = jsonencode({
    "source": ["aws.elb"]
  })
}

resource "aws_cloudwatch_event_rule" "cloudfront_event_rule" {
  name        = "CloudFront-Log-Rule"
  description = "Capture CloudFront access logs"
  event_pattern = jsonencode({
    "source": ["aws.cloudfront"]
  })
}

resource "aws_cloudwatch_event_target" "ec2_event_target" {
  rule      = aws_cloudwatch_event_rule.ec2_event_rule.name
  target_id = "ec2-logs-target"
  arn       = aws_cloudwatch_log_group.prod_log_group.arn

  input_transformer {
    input_paths = {
      logGroupName  = "$.detail.logGroupName"
      logStreamName = "$.detail.logStreamName"
    }
    input_template = <<-EOT
      {
        "logGroupName": <logGroupName>,
        "logStreamName": <logStreamName>
      }
    EOT
  }
}

resource "aws_cloudwatch_event_target" "alb_event_target" {
  rule      = aws_cloudwatch_event_rule.alb_event_rule.name
  target_id = "alb-logs-target"
  arn       = aws_cloudwatch_log_group.prod_log_group.arn

  input_transformer {
    input_paths = {
      logGroupName  = "$.detail.logGroupName"
      logStreamName = "$.detail.logStreamName"
    }
    input_template = <<-EOT
      {
        "logGroupName": <logGroupName>,
        "logStreamName": <logStreamName>
      }
    EOT
  }
}

resource "aws_cloudwatch_event_target" "cloudfront_event_target" {
  rule      = aws_cloudwatch_event_rule.cloudfront_event_rule.name
  target_id = "cloudfront-logs-target"
  arn       = aws_cloudwatch_log_group.prod_log_group.arn

  input_transformer {
    input_paths = {
      logGroupName  = "$.detail.logGroupName"
      logStreamName = "$.detail.logStreamName"
    }
    input_template = <<-EOT
      {
        "logGroupName": <logGroupName>,
        "logStreamName": <logStreamName>
      }
    EOT
  }
}
