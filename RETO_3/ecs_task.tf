# ──────────────────────────────────────────────
# Retrieve existing LabRole ARN (no new IAM roles created)
# ──────────────────────────────────────────────
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# ──────────────────────────────────────────────
# CloudWatch Log Group (referenced in task def)
# ──────────────────────────────────────────────
# Defined here so the task definition can reference it directly.
# Full CloudWatch alarms are in cloudwatch.tf.
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}-app"
  retention_in_days = 7

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# ──────────────────────────────────────────────
# ECS Task Definition
# ──────────────────────────────────────────────
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"  # Required for Fargate
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory

  # LabRole is used for both execution (pull image, write logs)
  # and task (runtime AWS API calls) — no new IAM roles created.
  execution_role_arn = data.aws_iam_role.lab_role.arn
  task_role_arn      = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.project_name}-container"
      image     = var.container_image
      essential = true

      portMappings = [
        {
          containerPort = var.app_port
          hostPort      = var.app_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "PROJECT"
          value = var.project_name
        },
        {
          name  = "PORT"
          value = tostring(var.app_port)
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      # Health check at container level
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.app_port}/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-task"
    Project     = var.project_name
    Environment = var.environment
  }
}
