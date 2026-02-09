# Data sources for existing resources
data "aws_vpc" "existing" {
  default = true
}

data "aws_subnets" "existing" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }
}

data "aws_subnet" "selected" {
  id = data.aws_subnets.existing.ids[0]
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = [var.ami_name_filter]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group - No SSH, only SSM access
resource "aws_security_group" "instances" {
  name_prefix = "${var.project_name}-instances-"
  description = "Security group for EC2 instances - SSM access only"
  vpc_id      = data.aws_vpc.existing.id

  # HTTPS outbound for SSM
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS for SSM"
  }

  # HTTP outbound for updates
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP for package updates"
  }

  tags = {
    Name        = "${var.project_name}-instances-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# EC2 Instances
resource "aws_instance" "servers" {
  for_each = var.instances

  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnet.selected.id
  vpc_security_group_ids = [aws_security_group.instances.id]
  iam_instance_profile   = var.iam_instance_profile_name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y amazon-ssm-agent
              systemctl enable amazon-ssm-agent
              systemctl start amazon-ssm-agent
              EOF

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name        = each.value.name
    Role        = each.value.role
    Environment = var.environment
    Project     = var.project_name
  }
}

# SSM Parameter Store - Common parameters
resource "aws_ssm_parameter" "common_region" {
  name  = "/repte6/common/region"
  type  = "String"
  value = var.aws_region

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# SSM Parameter Store - Web parameters
resource "aws_ssm_parameter" "web_port" {
  name  = "/repte6/web/port"
  type  = "String"
  value = "8080"

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Role        = "web"
  }
}

# SSM Parameter Store - App parameters
resource "aws_ssm_parameter" "app_log_level" {
  name  = "/repte6/app/log_level"
  type  = "String"
  value = "INFO"

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Role        = "app"
  }
}

# SSM Parameter Store - DB parameters
resource "aws_ssm_parameter" "db_name" {
  name  = "/repte6/db/db_name"
  type  = "String"
  value = "labdb"

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Role        = "db"
  }
}

resource "aws_ssm_parameter" "db_user" {
  name  = "/repte6/db/db_user"
  type  = "String"
  value = "labuser"

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Role        = "db"
  }
}

# SSM Document for automatic shutdown (optional - run manually to stop instances)
resource "aws_ssm_document" "stop_instances" {
  name            = "${var.project_name}-stop-instances"
  document_type   = "Command"
  document_format = "YAML"

  content = <<-DOC
    schemaVersion: '2.2'
    description: Stop EC2 instances to save credits
    mainSteps:
      - action: aws:runShellScript
        name: stopInstance
        inputs:
          runCommand:
            - echo "Instance will be stopped via AWS CLI or Console"
  DOC

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
