resource "aws_ecs_cluster" "tf_indexads_ecs" {
  name = "${var.project_name}-ecs"
}

resource "aws_ecs_task_definition" "tf_indexads_task" {
  family = var.project_name
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = 256
  memory = 512
  execution_role_arn = aws_iam_role.tf_indexads_role.arn
  task_role_arn = aws_iam_role.tf_indexads_role.arn
  container_definitions = jsonencode([
    {
      name = "${var.project_name}-task"
      image = "docker.io/nidjo13/${var.project_name}:latest"
      essential = true
      logConfiguration = {
          logDriver = "awslogs"
          options = {
              awslogs-group = aws_cloudwatch_log_group.tf_ecs_indexads_logs.id
              awslogs-region = "eu-central-1"
              awslogs-stream-prefix = "tf-ecs-${var.project_name}"
          }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "tf_ecs_indexads_logs" {
  name = "${var.project_name}-ecs-logs"
}