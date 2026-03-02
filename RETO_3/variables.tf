variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for naming and tagging"
  type        = string
  default     = "reto3"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "lab"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.3.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the two public subnets (ALB requires >=2 AZs)"
  type        = list(string)
  default     = ["10.3.1.0/24", "10.3.2.0/24"]
}

variable "app_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 5000
}

variable "container_image" {
  description = "Full ECR image URI. Leave empty on first apply; update after push."
  type        = string
  default     = "public.ecr.aws/docker/library/nginx:alpine"
  # Replace with your ECR URL after: docker build + docker push
}

variable "fargate_cpu" {
  description = "Fargate CPU units (256 = 0.25 vCPU)"
  type        = number
  default     = 256
}

variable "fargate_memory" {
  description = "Fargate memory in MiB"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}

variable "autoscaling_min" {
  description = "Minimum number of ECS tasks for auto-scaling"
  type        = number
  default     = 1
}

variable "autoscaling_max" {
  description = "Maximum number of ECS tasks for auto-scaling"
  type        = number
  default     = 3
}

variable "cpu_scale_threshold" {
  description = "CPU % threshold that triggers scale-out"
  type        = number
  default     = 70
}
