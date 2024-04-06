resource "aws_sfn_state_machine" "tf_indexads_sfn" {
  name     = "${var.project_name}-sfn"
  role_arn = aws_iam_role.tf_indexads_role.arn

  definition = <<EOF
{
  "Comment": "A description of my state machine",
  "StartAt": "ParallelScrape",
  "States": {
    "ParallelScrape": {
      "Type": "Parallel",
      "Branches": [
        {
          "StartAt": "ECSRunTaskCars",
          "States": {
            "ECSRunTaskCars": {
              "Type": "Task",
              "Resource": "arn:aws:states:::ecs:runTask.sync",
              "Parameters": {
                "LaunchType": "FARGATE",
                "Cluster": "${aws_ecs_cluster.tf_indexads_ecs.arn}",
                "TaskDefinition": "${aws_ecs_task_definition.tf_indexads_task.arn}",
                "NetworkConfiguration": {
                  "AwsvpcConfiguration": {
                    "Subnets": ${jsonencode(aws_subnet.public_subnet[*].id)},
                    "SecurityGroups": ["${aws_security_group.tf_ecs_security_group.id}"],
                    "AssignPublicIp": "ENABLED"
                  }
                },
                "Overrides": {
                  "ContainerOverrides": [
                    {
                      "Name": "tf-indexads-task",
                      "Environment": [
                        {
                          "Name": "NAME",
                          "Value": "cars"
                        }
                      ]
                    }
                  ]
                }
              },
              "End": true
            }
          }
        },
        {
          "StartAt": "ECSRunTaskApartments",
          "States": {
            "ECSRunTaskApartments": {
              "Type": "Task",
              "Resource": "arn:aws:states:::ecs:runTask.sync",
              "Parameters": {
                "LaunchType": "FARGATE",
                "Cluster": "${aws_ecs_cluster.tf_indexads_ecs.arn}",
                "TaskDefinition": "${aws_ecs_task_definition.tf_indexads_task.arn}",
                "NetworkConfiguration": {
                  "AwsvpcConfiguration": {
                    "Subnets": ${jsonencode(aws_subnet.public_subnet[*].id)},
                    "SecurityGroups": ["${aws_security_group.tf_ecs_security_group.id}"],
                    "AssignPublicIp": "ENABLED"
                  }
                },
                "Overrides": {
                  "ContainerOverrides": [
                    {
                      "Name": "tf-indexads-task",
                      "Environment": [
                        {
                          "Name": "NAME",
                          "Value": "apartments"
                        }
                      ]
                    }
                  ]
                }
              },
              "End": true
            }
          }
        },
        {
          "StartAt": "ECSRunTaskHouses",
          "States": {
            "ECSRunTaskHouses": {
              "Type": "Task",
              "Resource": "arn:aws:states:::ecs:runTask.sync",
              "Parameters": {
                "LaunchType": "FARGATE",
                "Cluster": "${aws_ecs_cluster.tf_indexads_ecs.arn}",
                "TaskDefinition": "${aws_ecs_task_definition.tf_indexads_task.arn}",
                "NetworkConfiguration": {
                  "AwsvpcConfiguration": {
                    "Subnets": ${jsonencode(aws_subnet.public_subnet[*].id)},
                    "SecurityGroups": ["${aws_security_group.tf_ecs_security_group.id}"],
                    "AssignPublicIp": "ENABLED"
                  }
                },
                "Overrides": {
                  "ContainerOverrides": [
                    {
                      "Name": "tf-indexads-task",
                      "Environment": [
                        {
                          "Name": "NAME",
                          "Value": "houses"
                        }
                      ]
                    }
                  ]
                }
              },
              "End": true
            }
          }
        }
      ],
      "Next": "StartCrawler"
    },
    "StartCrawler": {
      "Type": "Task",
      "Parameters": {
        "Name": "${aws_glue_crawler.tf_indexads_crawler.name}"
      },
      "Resource": "arn:aws:states:::aws-sdk:glue:startCrawler",
      "Next": "GetCrawler"
    },
    "GetCrawler": {
      "Type": "Task",
      "Next": "IsItRunning",
      "Parameters": {
        "Name": "${aws_glue_crawler.tf_indexads_crawler.name}"
      },
      "Resource": "arn:aws:states:::aws-sdk:glue:getCrawler"
    },
    "IsItRunning": {
      "Type": "Choice",
      "Choices": [
        {
          "Or": [
            {
              "Variable": "$.Crawler.State",
              "StringEquals": "RUNNING"
            },
            {
              "Variable": "$.Crawler.State",
              "StringEquals": "STOPPING"
            }
          ],
          "Next": "WaitForCrawler"
        }
      ],
      "Default": "EndIfDone"
    },
    "WaitForCrawler": {
      "Type": "Wait",
      "Seconds": 20,
      "Next": "GetCrawler"
    },
    "EndIfDone": {
      "Type": "Pass",
      "Next": "ParallelAthenaQueries"
    },
    "ParallelAthenaQueries": {
      "Type": "Parallel",
      "End": true,
      "Branches": [
        {
          "StartAt": "Athena StartQueryExecutionCars",
          "States": {
            "Athena StartQueryExecutionCars": {
              "Type": "Task",
              "Resource": "arn:aws:states:::athena:startQueryExecution.sync",
              "Parameters": {
                "QueryString": "${aws_athena_named_query.query_cars.query}",
                "QueryExecutionContext": { 
                  "Database": "${aws_glue_catalog_database.tf_indexads_database.name}"
                },
                "WorkGroup": "${aws_athena_workgroup.athena_workgroup.name}"
              },
              "Next": "Athena GetQueryResultsCars"
            },
            "Athena GetQueryResultsCars": {
              "Type": "Task",
              "Resource": "arn:aws:states:::athena:getQueryResults",
              "Parameters": {
                "QueryExecutionId.$": "$.QueryExecution.QueryExecutionId"
              },
              "Next": "SendQueryResultsCars"
            },
            "SendQueryResultsCars": {
              "Type": "Task",
              "Resource": "arn:aws:states:::sns:publish",
              "Parameters": {
                "TopicArn": "${aws_sns_topic.tf_indexads_athena_sns.arn}",
                "Message": {
                  "Input.$": "$.ResultSet.Rows"
                }
              },
              "End": true
            }
          }
        },
        {
          "StartAt": "Athena StartQueryExecutionApartments",
          "States": {
            "Athena StartQueryExecutionApartments": {
              "Type": "Task",
              "Resource": "arn:aws:states:::athena:startQueryExecution.sync",
              "Parameters": {
                "QueryString": "${aws_athena_named_query.query_apartments.query}",
                "QueryExecutionContext": { 
                  "Database": "${aws_glue_catalog_database.tf_indexads_database.name}"
                },
                "WorkGroup": "${aws_athena_workgroup.athena_workgroup.name}"
              },
              "Next": "Athena GetQueryResultsApartments"
            },
            "Athena GetQueryResultsApartments": {
              "Type": "Task",
              "Resource": "arn:aws:states:::athena:getQueryResults",
              "Parameters": {
                "QueryExecutionId.$": "$.QueryExecution.QueryExecutionId"
              },
              "Next": "SendQueryResultsApartments"
            },
            "SendQueryResultsApartments": {
              "Type": "Task",
              "Resource": "arn:aws:states:::sns:publish",
              "Parameters": {
                "TopicArn": "${aws_sns_topic.tf_indexads_athena_sns.arn}",
                "Message": {
                  "Input.$": "$.ResultSet.Rows"
                }
              },
              "End": true
            }
          }
        },
        {
          "StartAt": "Athena StartQueryExecutionHouses",
          "States": {
            "Athena StartQueryExecutionHouses": {
              "Type": "Task",
              "Resource": "arn:aws:states:::athena:startQueryExecution.sync",
              "Parameters": {
                "QueryString": "${aws_athena_named_query.query_houses.query}",
                "QueryExecutionContext": { 
                  "Database": "${aws_glue_catalog_database.tf_indexads_database.name}"
                },
                "WorkGroup": "${aws_athena_workgroup.athena_workgroup.name}"
              },
              "Next": "Athena GetQueryResultsHouses"
            },
            "Athena GetQueryResultsHouses": {
              "Type": "Task",
              "Resource": "arn:aws:states:::athena:getQueryResults",
              "Parameters": {
                "QueryExecutionId.$": "$.QueryExecution.QueryExecutionId"
              },
              "Next": "SendQueryResultsHouses"
            },
            "SendQueryResultsHouses": {
              "Type": "Task",
              "Resource": "arn:aws:states:::sns:publish",
              "Parameters": {
                "TopicArn": "${aws_sns_topic.tf_indexads_athena_sns.arn}",
                "Message": {
                  "Input.$": "$.ResultSet.Rows"
                }
              },
              "End": true
            }
          }
        }
      ]
    }
  }
}
EOF
}