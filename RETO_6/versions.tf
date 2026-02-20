# ──────────────────────────────────────────────
# Reto 6 — Gestión centralizada con AWS SSM
# Versiones requeridas de Terraform y providers
# ──────────────────────────────────────────────

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
