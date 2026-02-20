# AWS Systems Manager Lab - Infraestructura Completa

## Descripción

Este proyecto Terraform crea una infraestructura completa en AWS con:

- **VPC nueva** con subnets públicas y privadas en 2 zonas de disponibilidad
- **Internet Gateway** y tablas de rutas configuradas
- **3 instancias EC2** (web, app, db) con Amazon Linux 2023
- **IAM Role** personalizado para Systems Manager
- **VPC Endpoints** para acceso SSM desde subnets privadas
- **Security Groups** para tráfico interno y salida a internet
- **Parameter Store** con parámetros de ejemplo

## Arquitectura

```
VPC (10.0.0.0/16)
├── Public Subnets (10.0.0.0/24, 10.0.1.0/24)
│   └── Web Server (con IP pública)
├── Private Subnets (10.0.10.0/24, 10.0.11.0/24)
│   ├── App Server
│   └── DB Server
├── Internet Gateway
└── VPC Endpoints (SSM, SSMMessages, EC2Messages)
```

## Despliegue

```bash
terraform init
terraform plan
terraform apply
```

## Acceso a instancias (Session Manager)

Todas las instancias son accesibles vía Session Manager sin necesidad de SSH:

```bash
# Web Server
aws ssm start-session --target <web-server-id>

# App Server
aws ssm start-session --target <app-server-id>

# DB Server
aws ssm start-session --target <db-server-id>
```

Los comandos exactos se muestran en los outputs después de `terraform apply`.

## Gestión con Systems Manager

### Run Command
Ejecutar comandos en todas las instancias:

```bash
aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --targets "Key=tag:Project,Values=SSM-Lab" \
  --parameters 'commands=["yum update -y"]'
```

### Parameter Store
Consultar parámetros configurados:

```bash
aws ssm get-parameters-by-path --path "/lab/ssm" --recursive --with-decryption
```

### Patch Manager
Las instancias están configuradas para usar Patch Manager con la baseline por defecto.

## Variables Personalizables

Editar `variables.tf` o crear `terraform.tfvars`:

```hcl
aws_region    = "eu-west-1"
project_name  = "SSM-Lab"
instance_type = "t2.micro"
vpc_cidr      = "10.0.0.0/16"
```

## Limpieza

```bash
terraform destroy
```

## Notas Importantes

- **Web Server**: Desplegado en subnet pública con IP pública
- **App y DB Servers**: Desplegados en subnets privadas sin acceso directo desde internet
- **VPC Endpoints**: Permiten que las instancias privadas se conecten a SSM sin internet
- **Sin SSH**: Todo el acceso se realiza mediante Session Manager
- **IAM Role**: Creado específicamente para este lab con permisos mínimos necesarios
