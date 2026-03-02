# ──────────────────────────────────────────────
# Outputs
# ──────────────────────────────────────────────

output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = "http://${aws_lb.main.dns_name}"
}

output "ecr_repository_url" {
  description = "ECR repository URL – use this to tag and push your Docker image"
  value       = aws_ecr_repository.app.repository_url
}

output "ecs_cluster_name" {
  description = "ECS Cluster name"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "ECS Service name"
  value       = aws_ecs_service.app.name
}

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group for ECS task logs"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "docker_build_and_push_commands" {
  description = "Commands to build and push your Docker image to ECR"
  value       = <<-EOT

    # 1. Authenticate Docker to ECR
    aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.app.repository_url}

    # 2. Build the image (run from the repo root)
    docker build -t ${var.project_name}-app ./app

    # 3. Tag the image
    docker tag ${var.project_name}-app:latest ${aws_ecr_repository.app.repository_url}:latest

    # 4. Push to ECR
    docker push ${aws_ecr_repository.app.repository_url}:latest

    # 5. Force ECS to deploy new image
    aws ecs update-service --cluster ${aws_ecs_cluster.main.name} --service ${aws_ecs_service.app.name} --force-new-deployment --region ${var.aws_region}

  EOT
}

output "load_test_command" {
  description = "Quick load test with Apache Bench (ab) – install ab first"
  value       = "ab -n 10000 -c 50 http://${aws_lb.main.dns_name}/"
}
