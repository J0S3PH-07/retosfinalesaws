# ──────────────────────────────────────────────
# Reto 6 — Variables
# ──────────────────────────────────────────────

variable "aws_region" {
  description = "Región de AWS donde se despliegan los recursos"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto para etiquetas y nombrado"
  type        = string
  default     = "reto6"
}

variable "environment" {
  description = "Entorno de despliegue"
  type        = string
  default     = "lab"
}

variable "vpc_cidr" {
  description = "Bloque CIDR de la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Bloque CIDR de la subnet pública"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t2.micro"
}

variable "lab_role_name" {
  description = "Nombre del rol IAM existente del laboratorio"
  type        = string
  default     = "LabRole"
}
