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
          "StartAt": "AthenaStartQueryExecutionCars",
          "States": {
            "AthenaStartQueryExecutionCars": {
              "Type": "Task",
              "Resource": "arn:aws:states:::athena:startQueryExecution.sync",
              "Parameters": {
                "QueryString": "${aws_athena_named_query.query_cars.query}",
                "QueryExecutionContext": { 
                  "Database": "${aws_glue_catalog_database.tf_indexads_database.name}"
                },
                "WorkGroup": "${aws_athena_workgroup.athena_workgroup.name}"
              },
              "Next": "LambdaInvokeCars"
            },
            "LambdaInvokeCars": {
              "Type": "Task",
              "Resource": "arn:aws:states:::lambda:invoke.waitForTaskToken",
              "OutputPath": "$.Payload",
              "Parameters": {
                "Payload.$": "$",
                "FunctionName": "${aws_lambda_function.lambda_function.arn}:$LATEST",
                "S3Path.$": "$.QueryExecution.ResultConfiguration.OutputLocation",
                "Category": "Cars"
              },
              "Retry": [
                {
                  "ErrorEquals": [
                    "Lambda.ServiceException",
                    "Lambda.AWSLambdaException",
                    "Lambda.SdkClientException",
                    "Lambda.TooManyRequestsException"
                  ],
                  "IntervalSeconds": 1,
                  "MaxAttempts": 3,
                  "BackoffRate": 2
                }
              ],
              "End": true
            }
          }
        },
        {
          "StartAt": "AthenaStartQueryExecutionApartments",
          "States": {
            "AthenaStartQueryExecutionApartments": {
              "Type": "Task",
              "Resource": "arn:aws:states:::athena:startQueryExecution.sync",
              "Parameters": {
                "QueryString": "${aws_athena_named_query.query_apartments.query}",
                "QueryExecutionContext": { 
                  "Database": "${aws_glue_catalog_database.tf_indexads_database.name}"
                },
                "WorkGroup": "${aws_athena_workgroup.athena_workgroup.name}"
              },
              "Next": "LambdaInvokeApartments"
            },
            "LambdaInvokeApartments": {
              "Type": "Task",
              "Resource": "arn:aws:states:::lambda:invoke.waitForTaskToken",
              "OutputPath": "$.Payload",
              "Parameters": {
                "Payload.$": "$",
                "FunctionName": "${aws_lambda_function.lambda_function.arn}:$LATEST",
                "S3Path.$": "$.QueryExecution.ResultConfiguration.OutputLocation",
                "Category": "Apartments"
              },
              "Retry": [
                {
                  "ErrorEquals": [
                    "Lambda.ServiceException",
                    "Lambda.AWSLambdaException",
                    "Lambda.SdkClientException",
                    "Lambda.TooManyRequestsException"
                  ],
                  "IntervalSeconds": 1,
                  "MaxAttempts": 3,
                  "BackoffRate": 2
                }
              ],
              "End": true
            }
          }
        },
        {
          "StartAt": "AthenaStartQueryExecutionHouses",
          "States": {
            "AthenaStartQueryExecutionHouses": {
              "Type": "Task",
              "Resource": "arn:aws:states:::athena:startQueryExecution.sync",
              "Parameters": {
                "QueryString": "${aws_athena_named_query.query_houses.query}",
                "QueryExecutionContext": { 
                  "Database": "${aws_glue_catalog_database.tf_indexads_database.name}"
                },
                "WorkGroup": "${aws_athena_workgroup.athena_workgroup.name}"
              },
              "Next": "LambdaInvokeHouses"
            },
            "LambdaInvokeHouses": {
              "Type": "Task",
              "Resource": "arn:aws:states:::lambda:invoke.waitForTaskToken",
              "OutputPath": "$.Payload",
              "Parameters": {
                "Payload.$": "$",
                "FunctionName": "${aws_lambda_function.lambda_function.arn}:$LATEST",
                "S3Path.$": "$.QueryExecution.ResultConfiguration.OutputLocation",
                "Category": "Houses"
              },
              "Retry": [
                {
                  "ErrorEquals": [
                    "Lambda.ServiceException",
                    "Lambda.AWSLambdaException",
                    "Lambda.SdkClientException",
                    "Lambda.TooManyRequestsException"
                  ],
                  "IntervalSeconds": 1,
                  "MaxAttempts": 3,
                  "BackoffRate": 2
                }
              ],
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