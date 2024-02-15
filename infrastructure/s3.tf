resource "aws_s3_bucket" "tf_indexads_bucket" {
  bucket = "tf-indexads-bucket"
  
}

resource "aws_s3_bucket" "tf_indexads_athena_bucket" {
  bucket = "tf-indexads-athena-bucket"
}