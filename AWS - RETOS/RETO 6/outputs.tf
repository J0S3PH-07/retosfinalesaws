output "vpc_id" {
  description = "VPC ID being used"
  value       = data.aws_vpc.existing.id
}

output "subnet_id" {
  description = "Subnet ID being used"
  value       = data.aws_subnet.selected.id
}

output "security_group_id" {
  description = "Security Group ID for instances"
  value       = aws_security_group.instances.id
}

output "instance_ids" {
  description = "Map of instance IDs"
  value = {
    for k, v in aws_instance.servers : k => v.id
  }
}

output "instance_private_ips" {
  description = "Map of instance private IPs"
  value = {
    for k, v in aws_instance.servers : k => v.private_ip
  }
}

output "ssm_parameters" {
  description = "SSM Parameter Store paths created"
  value = {
    common_region    = aws_ssm_parameter.common_region.name
    web_port         = aws_ssm_parameter.web_port.name
    app_log_level    = aws_ssm_parameter.app_log_level.name
    db_name          = aws_ssm_parameter.db_name.name
    db_user          = aws_ssm_parameter.db_user.name
  }
}

output "session_manager_urls" {
  description = "AWS Console URLs for Session Manager access"
  value = {
    for k, v in aws_instance.servers : k => "https://console.aws.amazon.com/systems-manager/session-manager/${v.id}?region=${var.aws_region}"
  }
}

output "stop_instances_command" {
  description = "AWS CLI command to stop all instances"
  value       = "aws ec2 stop-instances --instance-ids ${join(" ", [for v in aws_instance.servers : v.id])} --region ${var.aws_region}"
}
