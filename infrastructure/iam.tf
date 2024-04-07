resource "aws_iam_role" "tf_indexads_role" {
  name = "${var.project_name}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # execute task on its own
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal : {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
      # execute it using sfn
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      },
      # glue
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      },
      # scheduler
      {
        "Effect" = "Allow",
        "Principal" = {
          "Service" = "scheduler.amazonaws.com"
        },
        "Action" = "sts:AssumeRole"
      },
      # lambda
      {
        "Effect" = "Allow",
        "Principal" = {
          "Service" = "lambda.amazonaws.com"
        },
        "Action" = "sts:AssumeRole"
      },
    ]
  })
}

resource "aws_iam_role_policy" "combined_policy" {
  name = "CombinedIAMPolicy"
  role = aws_iam_role.tf_indexads_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "iam:*",
          "logs:*",
          "s3:*",
          "sns:*",
          "states:*",
          "ecs:*",
          "glue:*",
          "events:*",
          "athena:*",
          "lambda:*",
          "secretsmanager:*"
        ],
        Resource = "*"
      }
    ]
  })
}