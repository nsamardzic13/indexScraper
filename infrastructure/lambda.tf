data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "../lambda"
  output_path = "../lambda.zip"
}

resource "aws_s3_object" "upload-lambda-script" {
  bucket      = aws_s3_bucket.tf_indexads_bucket.bucket
  key         = "scripts/lambda.zip"
  source      = data.archive_file.lambda.output_path
  source_hash = data.archive_file.lambda.output_base64sha256

  depends_on = [aws_s3_bucket.tf_indexads_bucket]
}

# Define the Lambda function
resource "aws_lambda_function" "lambda_function" {
  function_name = "${var.project_name}-sendemail"
  description   = "Lambda function to send email"
  handler       = "main.lambda_handler"
  runtime       = "python3.10"
  timeout       = 300
  role          = aws_iam_role.tf_indexads_role.arn
  s3_bucket     = aws_s3_bucket.tf_indexads_bucket.bucket
  s3_key        = aws_s3_object.upload-lambda-script.key

  source_code_hash = base64sha256(data.archive_file.lambda.output_path)
  environment {
    variables = {
      TARGET_EMAIL = "${var.sns_email_address}"
    }
  }

  layers = var.lambda_layers
}