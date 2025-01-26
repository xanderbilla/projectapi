resource "aws_cloudwatch_event_target" "ssm_run_command_target" {
    rule      = var.cloudwatch_event_rule_name
    target_id = "ssm-command-target"
    arn       = var.ssm_document_arn

    run_command_targets {
        key    = "InstanceIds"
        values = var.ec2_instance_ids
    }

    role_arn = var.eventbridge_ssm_role_arn
}