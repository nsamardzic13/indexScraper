resource "aws_sfn_state_machine" "tf_indexads_sfn" {
  name     = "tf-indexads-sfn"
  role_arn = aws_iam_role.tf_indexads_role.arn

  definition = <<EOF
{
  "Comment": "A description of my state machine",
  "StartAt": "Parallel Scrape",
  "States": {
    "Parallel Scrape": {
      "Type": "Parallel",
      "Branches": [
        {
          "StartAt": "ECS RunTask Cars",
          "States": {
            "ECS RunTask Cars": {
              "Type": "Task",
              "Resource": "arn:aws:states:::ecs:runTask.sync",
              "Parameters": {
                "LaunchType": "FARGATE",
                "Cluster": "${aws_ecs_cluster.tf_indexads_ecs.arn}",
                "TaskDefinition": "${aws_ecs_task_definition.tf_indexads_task.arn}",
                "NetworkConfiguration": {
                  "AwsvpcConfiguration": {
                    "Subnets": ${jsonencode(aws_subnet.private_subnet[*].id)},
                    "SecurityGroups": ["${aws_security_group.tf_ecs_security_group.id}"]
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
          "StartAt": "ECS RunTask Apartments",
          "States": {
            "ECS RunTask Apartments": {
              "Type": "Task",
              "Resource": "arn:aws:states:::ecs:runTask.sync",
              "Parameters": {
                "LaunchType": "FARGATE",
                "Cluster": "${aws_ecs_cluster.tf_indexads_ecs.arn}",
                "TaskDefinition": "${aws_ecs_task_definition.tf_indexads_task.arn}",
                "NetworkConfiguration": {
                  "AwsvpcConfiguration": {
                    "Subnets": ${jsonencode(aws_subnet.private_subnet[*].id)},
                    "SecurityGroups": ["${aws_security_group.tf_ecs_security_group.id}"]
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
          "StartAt": "ECS RunTask Houses",
          "States": {
            "ECS RunTask Houses": {
              "Type": "Task",
              "Resource": "arn:aws:states:::ecs:runTask.sync",
              "Parameters": {
                "LaunchType": "FARGATE",
                "Cluster": "${aws_ecs_cluster.tf_indexads_ecs.arn}",
                "TaskDefinition": "${aws_ecs_task_definition.tf_indexads_task.arn}",
                "NetworkConfiguration": {
                  "AwsvpcConfiguration": {
                    "Subnets": ${jsonencode(aws_subnet.private_subnet[*].id)},
                    "SecurityGroups": ["${aws_security_group.tf_ecs_security_group.id}"]
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
      "End": true,
      "Parameters": {
        "Name": "${aws_glue_crawler.tf_indexads_crawler.name}"
      },
      "Resource": "arn:aws:states:::aws-sdk:glue:startCrawler.waitForTaskToken"
    }
  }
}
EOF
}