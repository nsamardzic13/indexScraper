resource "aws_ecs_cluster" "tf_indexads_ecs" {
  name = "tf-indexads-ecs"
}

resource "aws_ecs_task_definition" "tf_indexads_task" {
  family = "tf-indexads"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = 256
  memory = 512
  execution_role_arn = aws_iam_role.tf_indexads_role.arn
  task_role_arn = aws_iam_role.tf_indexads_role.arn
  container_definitions = jsonencode([
    {
      name = "tf-indexads-task"
      image = "docker.io/nidjo13/indexads:latest"
      essential = true
      logConfiguration = {
          logDriver = "awslogs"
          options = {
              awslogs-group = aws_cloudwatch_log_group.tf_ecs_indexads_logs.id
              awslogs-region = "eu-central-1"
              awslogs-stream-prefix = "tf-ecs-indexads"
          }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "tf_ecs_indexads_logs" {
  name = "tf-ecs-indexads-logs"
}