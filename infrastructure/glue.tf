resource "aws_glue_catalog_database" "tf_indexads_database" {
  name = "${var.project_name}-database"
}

resource "aws_glue_crawler" "tf_indexads_crawler" {
  database_name = aws_glue_catalog_database.tf_indexads_database.name
  name          = "${var.project_name}-crawler"
  role          = aws_iam_role.tf_indexads_role.arn

  schema_change_policy {
    delete_behavior = "DELETE_FROM_DATABASE"
  }

  configuration = jsonencode(
    {
      CrawlerOutput = {
        Partitions = {
          AddOrUpdateBehavior = "InheritFromTable"
        }
      }
      Version = 1
    }
  )

  s3_target {
    path = "s3://${aws_s3_bucket.tf_indexads_bucket.bucket}"
  }
}