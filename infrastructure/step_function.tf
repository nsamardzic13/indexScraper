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
      "End": true
    }
  }
}
EOF
}