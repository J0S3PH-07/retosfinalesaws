# RETO 6 - AWS Systems Manager Lab

## Despliegue

```bash
terraform init
terraform plan
terraform apply
```

## Acceso a instancias

Usar Session Manager desde la consola AWS o AWS CLI:

```bash
aws ssm start-session --target <instance-id>
```

## Ejecutar comandos remotos

```bash
aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --targets "Key=tag:Project,Values=Repte6" \
  --parameters 'commands=["echo Hello from SSM"]'
```

## Consultar parámetros

```bash
aws ssm get-parameters-by-path --path "/repte6" --recursive
```

## Apagar instancias

```bash
terraform output -raw stop_instances_command | bash
```

O desde la consola:
EC2 > Instances > Seleccionar > Instance State > Stop

## Destruir infraestructura

```bash
terraform destroy
```
