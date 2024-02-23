resource "aws_cloudwatch_event_rule" "tf_cw_event_rule_sfn" {
  name = "${var.project_name}-cw-event-rule-sfn"
  description = "Trigger on Step function changes"
  event_pattern = jsonencode({
    source = ["aws.states"],
    detail-type = ["Step Functions Execution State Change"],
    detail = {
        "stateMachineArn": ["${aws_sfn_state_machine.tf_indexads_sfn.arn}"],
        "state": ["RUNNING", "SUCCEEDED", "ABORTED", "FAILED", "TIMED_OUT"]
    }
  })
}

resource "aws_sns_topic" "tf_indexads_sns_sfn" {
  name = "${var.project_name}-sns-sfn"
}

resource "aws_sns_topic_subscription" "tf_user_updates_sqs_target" {
  topic_arn = aws_sns_topic.tf_indexads_sns_sfn.arn
  protocol  = "email"
  endpoint  = var.sns_email_address
}

resource "aws_cloudwatch_event_target" "tf_indexads_sns_target_sfn" {
  target_id = "${var.project_name}-sns-target-sfn"
  rule      = aws_cloudwatch_event_rule.tf_cw_event_rule_sfn.name
  arn       = aws_sns_topic.tf_indexads_sns_sfn.arn
}