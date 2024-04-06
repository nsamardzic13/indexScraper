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

  force_destroy = true
}

# Terraform deletion of the WorkGroup
resource "null_resource" "delete_workgroup" {
  provisioner "local-exec" {
    command = "aws athena delete-work-group --work-group ${aws_athena_workgroup.athena_workgroup.name}"
  }
  # This will run the deletion command, you might want to ensure proper authentication
  # and permissions to run this command.
}

# resource "aws_athena_named_query" "query_cars" {
#   name      = "${var.project_name}-query_cars"
#   workgroup = aws_athena_workgroup.athena_workgroup.id
#   database  = aws_glue_catalog_database.tf_indexads_database.name
#   query     = <<EOT
#   WITH current_prices AS (
#     SELECT
#         url,
#         id,
#         cijena,
#         partitiondate as partitiondate
#     FROM \"tf-indexads-database\".\"cars\"
# ), previous_prices as (
#     SELECT
#         id,
#         cijena,
#         min(partitiondate) as partitiondate
#     FROM \"tf-indexads-database\".\"cars\"
#     group by 1,2
# )
# SELECT 
#     current.url,
#     current.id,
#     round((current.cijena - previous.cijena) / previous.cijena * 100, 2) as percent_change,
#     current.cijena AS current_cijena,
#     previous.cijena AS previous_cijena,
#     current.partitiondate AS latest_date,
#     previous.partitiondate as previous_date
# FROM current_prices AS current
# INNER JOIN previous_prices AS previous 
#     ON current.id = previous.id
# WHERE
#     current.cijena != previous.cijena
#     and date_parse(current.partitiondate, '%Y-%m-%d') >= current_date - interval '7' day
#     and current.partitiondate > previous.partitiondate
#     and round(current.cijena / previous.cijena, 2) > 0.2
# ORDER BY 
#     percent_change,
#     current.partitiondate desc
# ;
# EOT
# }

# resource "aws_athena_named_query" "query_apartments" {
#   name      = "${var.project_name}-query_apartments"
#   workgroup = aws_athena_workgroup.athena_workgroup.id
#   database  = aws_glue_catalog_database.tf_indexads_database.name
#   query     = <<EOT
#   WITH current_prices AS (
#     SELECT
#         url,
#         id,
#         cijena,
#         partitiondate as partitiondate
#     FROM \"tf-indexads-database\".\"apartments\"
# ), previous_prices as (
#     SELECT
#         id,
#         cijena,
#         min(partitiondate) as partitiondate
#     FROM \"tf-indexads-database\".\"apartments\"
#     group by 1,2
# )
# SELECT 
#     current.url,
#     current.id,
#     round((current.cijena - previous.cijena) / previous.cijena * 100, 2) as percent_change,
#     current.cijena AS current_cijena,
#     previous.cijena AS previous_cijena,
#     current.partitiondate AS latest_date,
#     previous.partitiondate as previous_date
# FROM current_prices AS current
# INNER JOIN previous_prices AS previous 
#     ON current.id = previous.id
# WHERE
#     current.cijena != previous.cijena
#     and date_parse(current.partitiondate, '%Y-%m-%d') >= current_date - interval '7' day
#     and current.partitiondate > previous.partitiondate
#     and round(current.cijena / previous.cijena, 2) > 0.2
# ORDER BY 
#     percent_change,
#     current.partitiondate desc
# ;
# EOT
# }

# resource "aws_athena_named_query" "query_houses" {
#   name      = "${var.project_name}-query_houses"
#   workgroup = aws_athena_workgroup.athena_workgroup.id
#   database  = aws_glue_catalog_database.tf_indexads_database.name
#   query     = <<EOT
#   WITH current_prices AS (
#     SELECT
#         url,
#         id,
#         cijena,
#         partitiondate as partitiondate
#     FROM \"tf-indexads-database\".\"houses\"
# ), previous_prices as (
#     SELECT
#         id,
#         cijena,
#         min(partitiondate) as partitiondate
#     FROM \"tf-indexads-database\".\"houses\"
#     group by 1,2
# )
# SELECT 
#     current.url,
#     current.id,
#     round((current.cijena - previous.cijena) / previous.cijena * 100, 2) as percent_change,
#     current.cijena AS current_cijena,
#     previous.cijena AS previous_cijena,
#     current.partitiondate AS latest_date,
#     previous.partitiondate as previous_date
# FROM current_prices AS current
# INNER JOIN previous_prices AS previous 
#     ON current.id = previous.id
# WHERE
#     current.cijena != previous.cijena
#     and date_parse(current.partitiondate, '%Y-%m-%d') >= current_date - interval '7' day
#     and current.partitiondate > previous.partitiondate
#     and round(current.cijena / previous.cijena, 2) > 0.2
# ORDER BY 
#     percent_change,
#     current.partitiondate desc
# ;
# EOT
# }