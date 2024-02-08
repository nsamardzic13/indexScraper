resource "aws_glue_catalog_database" "tf_indexads_database" {
  name = "tf-indexads-database"
}

resource "aws_glue_crawler" "tf_indexads_crawler" {
  database_name = aws_glue_catalog_database.tf_indexads_database.name
  name          = "tf-indexads-crawler"
  role          = aws_iam_role.tf_indexads_role.arn

  s3_target {
    path = "s3://${aws_s3_bucket.tf_indexads_bucket.bucket}"
  }
}