# ──────────────────────────────────────────────────────────────
# Reto 6 — Gestión centralizada con AWS Systems Manager
# Recursos: VPC, ALB, EC2 x3, SSM Parameter Store
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

# Zonas de disponibilidad (ALB requiere mínimo 2 AZs)
data "aws_availability_zones" "available" {
  state = "available"
}

# Perfil de instancia (Academia)
data "aws_iam_instance_profile" "lab_profile" {
  name = "LabInstanceProfile"
}

# Repositorio ECR (creado por Terraform)
resource "aws_ecr_repository" "app" {
  name                 = "reto6-app"
  image_tag_mutability = "MUTABLE"

  tags = {
    Project     = "reto6"
    Environment = "lab"
  }
}

# ============================================================
# RED — VPC, Internet Gateway, Route Table, Subnets
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

# Subnet pública 1 (AZ-a)
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_1
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-1"
  }
}

# Subnet pública 2 (AZ-b) — requerida por el ALB
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_2
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-2"
  }
}

# Asociaciones Route Table <-> Subnets
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# ============================================================
# SECURITY GROUPS
# ============================================================

# SG para las instancias EC2 (gestionadas por SSM, sin SSH)
resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-ec2-sg"
  description = "SG para EC2 gestionadas por SSM. Sin SSH. Permite HTTP desde ALB."
  vpc_id      = aws_vpc.main.id

  # Permitir HTTP desde el ALB
  ingress {
    description     = "HTTP desde ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Permitir todo el tráfico de salida (necesario para SSM y actualizaciones)
  egress {
    description = "Permitir todo el trafico de salida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}

# SG para el Application Load Balancer
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "SG para el ALB. Permite HTTP desde internet."
  vpc_id      = aws_vpc.main.id

  # Permitir HTTP desde internet
  ingress {
    description = "HTTP desde internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Permitir todo el tráfico de salida
  egress {
    description = "Permitir todo el trafico de salida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# ============================================================
# APPLICATION LOAD BALANCER
# ============================================================

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# Target Group para el web-server
resource "aws_lb_target_group" "web" {
  name     = "${var.project_name}-web-tg-v2"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-web-tg"
  }
}

# Listener HTTP en el ALB
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }

  tags = {
    Name = "${var.project_name}-http-listener"
  }
}

# Registrar web-server en el Target Group
resource "aws_lb_target_group_attachment" "web" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web_server.id
  port             = 80
}

# ============================================================
# EC2 — 3 instancias gestionadas por Systems Manager
# ============================================================

# --- web-server (con httpd instalado via user_data) ---
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_1.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  iam_instance_profile        = data.aws_iam_instance_profile.lab_profile.name
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    systemctl enable --now amazon-ssm-agent
    dnf update -y
    dnf install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Web Server - Reto 6 SSM</h1>" > /var/www/html/index.html
    dnf install -y samba
    systemctl enable smb
    systemctl start smb
  EOF

  tags = {
    Name = "web-server"
    Role = "web"
  }
}

# --- app-server ---
resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_1.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  iam_instance_profile        = data.aws_iam_instance_profile.lab_profile.name
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    systemctl enable --now amazon-ssm-agent
    dnf update -y
    dnf install -y samba
    systemctl enable smb
    systemctl start smb
  EOF

  tags = {
    Name = "app-server"
    Role = "app"
  }
}

# --- db-server ---
resource "aws_instance" "db_server" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_1.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  iam_instance_profile        = data.aws_iam_instance_profile.lab_profile.name
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    systemctl enable --now amazon-ssm-agent
    dnf update -y
    dnf install -y samba
    systemctl enable smb
    systemctl start smb
  EOF

  tags = {
    Name = "db-server"
    Role = "db"
  }
}

# ============================================================
# SYSTEMS MANAGER — Parameter Store
# ============================================================

# --- Parámetros de Web ---
resource "aws_ssm_parameter" "db_user" {
  name        = "/reto6/web/db_user"
  description = "Usuario para servidor web"
  type        = "String"
  value       = "admin_web"
  overwrite   = true
}

resource "aws_ssm_parameter" "db_password" {
  name        = "/reto6/web/db_password"
  description = "Contraseña para servidor web"
  type        = "SecureString"
  value       = "WebPass2026!"
  overwrite   = true
}

# --- Parámetros de App ---
resource "aws_ssm_parameter" "api_key" {
  name        = "/reto6/app/api_key"
  description = "API key para el backend"
  type        = "String"
  value       = "reto6-key-v1"
  overwrite   = true
}

# --- Parámetros de DB ---
resource "aws_ssm_parameter" "db_master_user" {
  name        = "/reto6/db/master_user"
  description = "Usuario maestro de DB"
  type        = "String"
  value       = "master_admin"
  overwrite   = true
}

# ============================================================
# SYSTEMS MANAGER — Automation & Run Command
# ============================================================

resource "aws_ssm_document" "mantenimiento_samba" {
  name          = "MantenimientoSamba-v2"
  document_type = "Command"
  content       = jsonencode({
    schemaVersion = "2.2"
    description   = "Actualiza paquetes y reinicia el servicio Samba"
    mainSteps = [
      {
        action = "aws:runShellScript"
        name   = "updateAndRestart"
        inputs = {
          runCommand = [
            "dnf update -y",
            "systemctl restart smb",
            "echo 'Mantenimiento completado exitosamente'"
          ]
        }
      }
    ]
  })

  tags = {
    Project = "reto6"
  }
}
