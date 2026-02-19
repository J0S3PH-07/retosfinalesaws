# ──────────────────────────────────────────────
# Reto 6 — Outputs
# ──────────────────────────────────────────────

# --- Red ---
output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "ID de la subnet pública"
  value       = aws_subnet.public.id
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
