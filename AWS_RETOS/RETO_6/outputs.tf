output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "alb_dns_name" {
  description = "Public DNS of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "ec2_instance_public_ip" {
  description = "Public IP of the EC2 App Server"
  value       = aws_instance.app_server[0].public_ip
}

output "ecs_cluster_name" {
  description = "Name of the ECS Cluster"
  value       = aws_ecs_cluster.main.name
}

output "ssm_parameter_name" {
  description = "Example SSM Parameter"
  value       = aws_ssm_parameter.example_param.name
}

output "ecr_repository_url" {
  description = "URL del repositorio ECR"
  value       = aws_ecr_repository.app.repository_url
}
