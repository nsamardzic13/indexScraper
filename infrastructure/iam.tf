resource "aws_iam_role" "tf_indexads_role" {
  name = "tf-indexads-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # execute task on its own
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal: {
          Service = "ecs-tasks.amazonaws.com" 
        }
      },
      # execute it using sfn
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service  = "states.amazonaws.com" 
        }
      },
      # glue
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service  = "glue.amazonaws.com" 
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "CloudWatchLogsFullAccess" {
  role = aws_iam_role.tf_indexads_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "AmazonS3FullAccess" {
  role = aws_iam_role.tf_indexads_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "SnsFullAccess" {
  role = aws_iam_role.tf_indexads_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}

resource "aws_iam_role_policy_attachment" "AWSStepFunctionsConsoleFullAccess" {
  role = aws_iam_role.tf_indexads_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSStepFunctionsConsoleFullAccess"
}

resource "aws_iam_role_policy_attachment" "AWSStepFunctionsFullAccess" {
  role = aws_iam_role.tf_indexads_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSStepFunctionsFullAccess"
}

resource "aws_iam_role_policy_attachment" "AmazonECS_FullAccess" {
  role       = aws_iam_role.tf_indexads_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

resource "aws_iam_role_policy_attachment" "AWSGlueServiceRole" {
  role       = aws_iam_role.tf_indexads_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}