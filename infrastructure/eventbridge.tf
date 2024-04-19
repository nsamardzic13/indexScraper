resource "aws_scheduler_schedule" "example" {
  name       = "${var.project_name}-schedule"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  # every 3 days
  schedule_expression = "cron(00 07 ? */3 ? *)"

  target {
    arn      = aws_sfn_state_machine.tf_indexads_sfn.arn
    role_arn = aws_iam_role.tf_indexads_role.arn
  }
}