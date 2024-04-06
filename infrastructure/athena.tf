resource "aws_s3_bucket" "tf_indexads_athena_bucket" {
  bucket        = "${var.project_name}-athena-bucket"
  force_destroy = true
}

resource "aws_athena_workgroup" "athena_workgroup" {
  name = "${var.project_name}-athena-workgroup"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.tf_indexads_athena_bucket.bucket}/output/"
    }
  }

  force_destroy = true
  depends_on    = [aws_s3_bucket.tf_indexads_athena_bucket]
}