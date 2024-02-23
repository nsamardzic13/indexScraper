resource "aws_s3_bucket" "tf_indexads_bucket" {
  bucket = "tf-${var.project_name}-bucket"
  
}

resource "aws_s3_bucket" "tf_indexads_athena_bucket" {
  bucket = "tf-${var.project_name}-athena-bucket"
}