resource "aws_cloudwatch_event_rule" "ecr_image_push_rule" {
  name        = "ecr-image-push-rule"
  description = "Triggered when a new image is pushed to ECR"
  event_pattern = <<EOT
  {
    "source": ["aws.ecr"],
    "detail-type": ["ECR Image Action"],
    "detail": {
      "action-type": ["PUSH"],
      "result": ["SUCCESS"],
      "repository-name": ["${var.repository_name}"],
      "image-tag": ["${var.image_tag}"]
    }
  }
  EOT
}
