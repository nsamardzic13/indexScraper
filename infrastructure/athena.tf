resource "aws_s3_bucket" "tf_indexads_athena_bucket" {
  bucket = "${var.project_name}-athena-bucket"
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
}

# https://stackoverflow.com/questions/73663082/json-parse-error-illegal-unquoted-character-ctrl-char-code-13/73664111#73664111

resource "aws_athena_named_query" "query_cars" {
  name      = "${var.project_name}-query_cars"
  workgroup = aws_athena_workgroup.athena_workgroup.id
  database  = aws_glue_catalog_database.tf_indexads_database.name
  query     = file("../athena_queries/cars.sql")
}

resource "aws_athena_named_query" "query_apartments" {
  name      = "${var.project_name}-query_apartments"
  workgroup = aws_athena_workgroup.athena_workgroup.id
  database  = aws_glue_catalog_database.tf_indexads_database.name
  query     = file("../athena_queries/apartments.sql")
}

resource "aws_athena_named_query" "query_houses" {
  name      = "${var.project_name}-query_houses"
  workgroup = aws_athena_workgroup.athena_workgroup.id
  database  = aws_glue_catalog_database.tf_indexads_database.name
  query     = file("../athena_queries/houses.sql")
}