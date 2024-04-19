resource "aws_cloudwatch_event_rule" "tf_cw_event_rule_sfn" {
  name        = "${var.project_name}-cw-event-rule-sfn"
  description = "Trigger on Step function changes"
  event_pattern = jsonencode({
    source      = ["aws.states"],
    detail-type = ["Step Functions Execution Status Change"],
    detail = {
      "stateMachineArn" : ["${aws_sfn_state_machine.tf_indexads_sfn.arn}"],
      "status" : ["SUCCEEDED", "ABORTED", "FAILED", "TIMED_OUT"]
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


resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.tf_indexads_sns_sfn.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com"
      ]
    }

    resources = [aws_sns_topic.tf_indexads_sns_sfn.arn]
  }
}