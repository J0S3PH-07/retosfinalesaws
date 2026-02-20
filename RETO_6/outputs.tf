# ──────────────────────────────────────────────
# Reto 6 — Outputs
# ──────────────────────────────────────────────

# --- Red ---
output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.main.id
}

output "subnet_id_1" {
  description = "ID de la subnet pública 1"
  value       = aws_subnet.public_1.id
}

output "subnet_id_2" {
  description = "ID de la subnet pública 2"
  value       = aws_subnet.public_2.id
}

# --- Load Balancer ---
output "alb_dns_name" {
  description = "URL del Application Load Balancer"
  value       = "http://${aws_lb.main.dns_name}"
}

# --- EC2 Instance IDs ---
output "web_server_instance_id" {
  description = "Instance ID del web-server"
  value       = aws_instance.web_server.id
}

output "app_server_instance_id" {
  description = "Instance ID del app-server"
  value       = aws_instance.app_server.id
}

output "db_server_instance_id" {
  description = "Instance ID del db-server"
  value       = aws_instance.db_server.id
}

# --- EC2 Private IPs ---
output "web_server_private_ip" {
  description = "IP privada del web-server"
  value       = aws_instance.web_server.private_ip
}

output "app_server_private_ip" {
  description = "IP privada del app-server"
  value       = aws_instance.app_server.private_ip
}

output "db_server_private_ip" {
  description = "IP privada del db-server"
  value       = aws_instance.db_server.private_ip
}

# --- AMI ---
output "ami_used" {
  description = "AMI de Amazon Linux 2023 utilizada"
  value       = data.aws_ami.amazon_linux_2023.id
}

# --- ECR ---
output "ecr_repository_url" {
  description = "URL del repositorio ECR (reto6-app)"
  value       = aws_ecr_repository.app.repository_url
}
