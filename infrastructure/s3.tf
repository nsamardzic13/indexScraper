resource "aws_s3_bucket" "tf_indexads_bucket" {
  bucket = "${var.project_name}-bucket"
}