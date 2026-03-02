# ──────────────────────────────────────────────
# ECS Service
# ──────────────────────────────────────────────
resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  # Allow new task to start before draining old task (zero-downtime deploys)
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true  # Needed for Fargate in public subnet to reach ECR
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "${var.project_name}-container"
    container_port   = var.app_port
  }

  # Ensure ALB listener is created before the service
  depends_on = [aws_lb_listener.http]

  tags = {
    Name        = "${var.project_name}-service"
    Project     = var.project_name
    Environment = var.environment
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
    # ignore_changes on task_definition allows CI/CD to update the image
    # without Terraform reverting it on the next apply.
  }
}

# ──────────────────────────────────────────────
# Auto Scaling – register ECS service as scalable target
# ──────────────────────────────────────────────
resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = var.autoscaling_max
  min_capacity       = var.autoscaling_min
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# ──────────────────────────────────────────────
# Auto Scaling Policy – scale OUT when CPU > threshold
# ──────────────────────────────────────────────
resource "aws_appautoscaling_policy" "scale_out_cpu" {
  name               = "${var.project_name}-scale-out-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = var.cpu_scale_threshold
    scale_in_cooldown  = 300
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}
