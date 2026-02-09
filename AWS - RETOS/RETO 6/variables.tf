variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "Repte6"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "Lab"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ami_name_filter" {
  description = "AMI name filter for Amazon Linux 2023"
  type        = string
  default     = "al2023-ami-*-x86_64"
}

variable "iam_instance_profile_name" {
  description = "Existing IAM instance profile name"
  type        = string
  default     = "c180546a4645463l13662792t1w194273254-LabEksNodeRole-kw4EqFiRePWX"
}

variable "instances" {
  description = "Map of instances to create"
  type = map(object({
    name = string
    role = string
  }))
  default = {
    web = {
      name = "web-server"
      role = "web"
    }
    app = {
      name = "app-server"
      role = "app"
    }
    db = {
      name = "db-server"
      role = "db"
    }
  }
}
