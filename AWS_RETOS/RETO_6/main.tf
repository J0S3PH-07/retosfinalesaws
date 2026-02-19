# ──────────────────────────────────────────────────────────────
# Reto 6 — Gestión centralizada con AWS Systems Manager
# Recursos principales: VPC, EC2, Security Group, SSM Parameters
# ──────────────────────────────────────────────────────────────

# ============================================================
# DATA SOURCES
# ============================================================

# AMI más reciente de Amazon Linux 2023 (x86_64)
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Zona de disponibilidad
data "aws_availability_zones" "available" {
  state = "available"
}

# ============================================================
# RED — VPC, Internet Gateway, Route Table, Subnet
# ============================================================

# VPC principal
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Route Table pública
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Subnet pública
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

# Asociación Route Table <-> Subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ============================================================
# SECURITY GROUP
# ============================================================

resource "aws_security_group" "ssm_sg" {
  name        = "${var.project_name}-ssm-sg"
  description = "Security Group para instancias gestionadas por SSM. Sin SSH."
  vpc_id      = aws_vpc.main.id

  # Sin reglas de ingreso — no se abre puerto 22 ni ningún otro.
  # SSM utiliza una conexión saliente desde el agente hacia los endpoints.

  # Permitir todo el tráfico de salida (necesario para SSM y actualizaciones)
  egress {
    description = "Permitir todo el trafico de salida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ssm-sg"
  }
}

# ============================================================
# IAM INSTANCE PROFILE — usando el rol existente LabRole
# ============================================================

resource "aws_iam_instance_profile" "lab_profile" {
  name = "${var.project_name}-lab-instance-profile"
  role = var.lab_role_name
}

# ============================================================
# EC2 — 3 instancias gestionadas por Systems Manager
# ============================================================

# --- web-server (con httpd instalado via user_data) ---
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ssm_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.lab_profile.name

  user_data = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Web Server - Reto 6 SSM</h1>" > /var/www/html/index.html
  EOF

  tags = {
    Name = "web-server"
    Role = "web"
  }
}

# --- app-server ---
resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ssm_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.lab_profile.name

  tags = {
    Name = "app-server"
    Role = "app"
  }
}

# --- db-server ---
resource "aws_instance" "db_server" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ssm_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.lab_profile.name

  tags = {
    Name = "db-server"
    Role = "db"
  }
}

# ============================================================
# SYSTEMS MANAGER — Parameter Store
# ============================================================

resource "aws_ssm_parameter" "db_host" {
  name        = "/reto6/web/db_host"
  description = "Host de la base de datos para el web-server"
  type        = "String"
  value       = aws_instance.db_server.private_ip

  tags = {
    Name = "${var.project_name}-param-db-host"
  }
}

resource "aws_ssm_parameter" "db_user" {
  name        = "/reto6/web/db_user"
  description = "Usuario de la base de datos"
  type        = "String"
  value       = "admin"

  tags = {
    Name = "${var.project_name}-param-db-user"
  }
}

resource "aws_ssm_parameter" "db_password" {
  name        = "/reto6/web/db_password"
  description = "Contraseña de la base de datos (cifrada)"
  type        = "SecureString"
  value       = "Reto6SecurePass2026!"

  tags = {
    Name = "${var.project_name}-param-db-password"
  }
}

resource "aws_ssm_parameter" "api_key" {
  name        = "/reto6/app/api_key"
  description = "API key para el app-server"
  type        = "String"
  value       = "reto6-api-key-2026"

  tags = {
    Name = "${var.project_name}-param-api-key"
  }
}
