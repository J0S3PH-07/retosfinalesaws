output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "web_server_id" {
  value = aws_instance.web_server.id
}

output "app_server_id" {
  value = aws_instance.app_server.id
}

output "db_server_id" {
  value = aws_instance.db_server.id
}

output "web_server_private_ip" {
  value = aws_instance.web_server.private_ip
}

output "app_server_private_ip" {
  value = aws_instance.app_server.private_ip
}

output "db_server_private_ip" {
  value = aws_instance.db_server.private_ip
}

output "security_group_id" {
  value = aws_security_group.instances.id
}

output "ssm_parameters" {
  value = {
    db_password = aws_ssm_parameter.db_password.name
    api_key     = aws_ssm_parameter.api_key.name
    app_config  = aws_ssm_parameter.app_config.name
  }
}

output "session_manager_commands" {
  value = {
    web_server = "aws ssm start-session --target ${aws_instance.web_server.id}"
    app_server = "aws ssm start-session --target ${aws_instance.app_server.id}"
    db_server  = "aws ssm start-session --target ${aws_instance.db_server.id}"
  }
}
