resource "aws_s3_bucket" "tf_indexads_bucket" {
  bucket = "${var.project_name}-bucket"
  
}

resource "aws_s3_bucket" "tf_indexads_athena_bucket" {
  bucket = "${var.project_name}-athena-bucket"
}