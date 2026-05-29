<div align="center">

# ☁️ Infraestructura AWS — Ritual Roast

Terraform para el entorno **`dev`** del proyecto **`ritual-roast`**

<br/>

![Terraform](https://img.shields.io/badge/Terraform-844FBA?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazonwebservices&logoColor=FF9900)
![VPC](https://img.shields.io/badge/VPC-8C4FFF?style=for-the-badge&logo=amazonvpc&logoColor=white)
![ECS](https://img.shields.io/badge/ECS_Fargate-FF9900?style=for-the-badge&logo=amazon-ecs&logoColor=white)
![ECR](https://img.shields.io/badge/ECR-FF9900?style=for-the-badge&logo=amazon-ecr&logoColor=white)
![RDS](https://img.shields.io/badge/RDS_MySQL-527FFF?style=for-the-badge&logo=amazonrds&logoColor=white)

<br/>

[← README del proyecto](../../README.md)

</div>

---

## Tabla de contenidos

1. [Resumen](#resumen)
2. [Requisitos](#requisitos)
3. [Inicio rápido](#inicio-rápido)
4. [Recursos creados](#recursos-creados)
5. [Alineación con el diagrama](#alineación-con-el-diagrama)
6. [Estructura de módulos](#estructura-de-módulos)
7. [Configuración](#configuración)
8. [Tráfico y balanceador](#tráfico-y-balanceador)
9. [EC2 de build](#ec2-de-build)
10. [ECS Fargate](#ecs-fargate)
11. [RDS y secretos](#rds-y-secretos)
12. [Outputs](#outputs)
13. [Orden de despliegue](#orden-de-despliegue)
14. [Problemas frecuentes](#problemas-frecuentes)
15. [Destruir el entorno](#destruir-el-entorno)

---

## Resumen

Este directorio define en Terraform:

- Una **VPC** con subnets públicas, de aplicación (webapp) y de datos.
- Un **Application Load Balancer** que expone el frontend y enruta `/api/*` al backend.
- **ECS Fargate** con dos servicios (Next.js y Flask) detrás de target groups tipo `ip`.
- **ECR** para las imágenes y una **EC2** que las construye y publica en el primer arranque.
- **RDS MySQL** y **Secrets Manager**, con rotación opcional vía Lambda en la VPC.

Región por defecto: **`us-east-1`**. Diagrama de referencia: [README del proyecto](../../README.md#arquitectura).

---

## Requisitos

| Requisito | Notas |
|-----------|--------|
| [Terraform](https://www.terraform.io/downloads) **>= 1.1** | |
| Cuenta AWS | Permisos sobre VPC, EC2, ECS, ECR, RDS, ALB, IAM, Secrets Manager, Lambda |
| AWS CLI | Credenciales o SSO para la región definida en `terraform.tfvars` |

---

## Inicio rápido

```powershell
cd terraform/aws
copy terraform.tfvars.example terraform.tfvars   # Windows
# Editar terraform.tfvars con tus valores (no commitear este archivo)

terraform init
terraform plan
terraform apply
```

Tras el apply, toma el output **`alb_dns_name`** y ábrelo en el navegador cuando los target groups estén en estado **healthy**.

---

## Recursos creados

| Bloque | Recursos principales |
|--------|----------------------|
| **Red** | VPC `10.0.0.0/16`, 2 subnets públicas, 2 webapp privadas, 2 data privadas, IGW, NAT |
| **Seguridad** | SG para ALB, aplicación web y MySQL (regla self en 3306 como recurso aparte) |
| **Entrada** | ALB HTTP `:80`, TG frontend `:3000`, TG backend `:5000`, regla `/api/*` |
| **Compute** | Cluster ECS y dos servicios Fargate (2 tareas por servicio por defecto) |
| **Imágenes** | Dos repositorios ECR; EC2 opcional con build/push en user-data |
| **Datos** | Instancia RDS MySQL, subnet group, secreto JSON, rotación Lambda opcional |
| **IAM** | Rol de ejecución ECS; rol EC2 con SSM, ECR push y lectura de secretos |

---

## Alineación con el diagrama

El diagrama en `Diagram/Arquitectura-microservicios-SSA.png` refleja la misma topología que este código:

| Zona del diagrama | Implementación en Terraform |
|-------------------|----------------------------|
| DMZ / público | `module.alb` + subnets públicas |
| Web/App privado | `module.ecs_cluster` + subnets `private_webapp` |
| Data privado | `module.rds_mysql` + subnets `private_data` |
| ECR y ECS | `module.ecr_*`, `module.ecs-fargate-service` |
| Secretos | `module.mysql_credentials_secret`, rotación Lambda |
| Build | `module.standalone_ec2` → publica imágenes en ECR |

---

## Estructura de módulos

```
terraform/aws/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example      # Plantilla (sí va a git)
├── templates/
│   └── ec2-docker-user-data.sh.tpl
└── modules/
    ├── vpc/
    ├── security-groups/
    ├── alb/
    ├── alb-target-group/
    ├── ecr-repository/
    ├── ec2-instance/
    ├── ec2-ssm-role/
    ├── ecs-cluster/              # Cluster + 2 servicios Fargate
    ├── ecs-fargate-service/        # Task definition + servicio + logs
    ├── ecs-task-execution-role/
    ├── db-subnet-group/
    ├── rds-aurora-mysql/           # aws_db_instance MySQL
    ├── mysql-credentials-secret/
    ├── mysql-rotation-lambda-sar/
    └── rds-mysql-master-secret-rotation/
```

---

## Configuración

Copia `terraform.tfvars.example` a `terraform.tfvars` y personaliza. Ejemplo de valores habituales:

```hcl
aws_region   = "us-east-1"
environment  = "dev"
project_name = "ritual-roast"
vpc_cidr     = "10.0.0.0/16"

standalone_ec2_instance_type  = "t3.small"
standalone_ec2_root_volume_gb = 40

# URLs de los ZIP con el código fuente (frontend y backend)
standalone_ec2_frontend_zip_url = "https://..."
standalone_ec2_backend_zip_url  = "https://..."

create_mysql_credentials_secret         = true
rds_mysql_enable_secret_rotation        = true
rds_mysql_rotation_lambda_deploy_in_vpc = true
```

### Variables relevantes

| Variable | Default | Efecto |
|----------|---------|--------|
| `standalone_ec2_enable` | `true` | Crea la EC2 que construye y sube imágenes |
| `ecr_enable` | `true` | Repositorios ECR e imágenes en las task definitions |
| `ecs_enable` | `true` | Cluster ECS |
| `ecs_backend_desired_count` / `ecs_frontend_desired_count` | `2` | Tareas Fargate por servicio |
| `ecs_image_tag` | `latest` | Tag de imagen en ECR y ECS |
| `standalone_ec2_build_and_push_ecr` | `true` | User-data ejecuta build y push (requiere `ecr_enable`) |

Archivos que **no** deben subirse a git (ya están en `.gitignore`): `terraform.tfvars`, `*.tfstate`, `.terraform/`.

---

## Tráfico y balanceador

```
Cliente
   │  HTTP :80
   ▼
Application Load Balancer (subnets públicas)
   │
   ├─ Prioridad 1: path /api/*  →  Target group backend (5000)  →  ECS Flask
   │
   └─ Default                   →  Target group frontend (3000) →  ECS Next.js
```

| Servicio | Health check |
|----------|----------------|
| Frontend | `GET /` |
| Backend | `GET /api/health` |

---

## EC2 de build

Recurso: `module.standalone_ec2` en `main.tf`.

| Aspecto | Valor |
|---------|--------|
| Subnet | Primera subnet privada **webapp** |
| Security group | **web_app** |
| Acceso | SSM Session Manager (sin SSH obligatorio) |
| Script de arranque | `templates/ec2-docker-user-data.sh.tpl` |

**Secuencia del user-data**

1. Comprobar conectividad saliente (IPv4).
2. Instalar Docker y herramientas necesarias.
3. Descargar y descomprimir el código fuente del frontend y backend.
4. Ajustar `app.py` con región y nombre del secreto de MySQL.
5. Autenticación en ECR, `docker build` y `docker push`.
6. Opcional: instalar el agente ECS (`ecs-init`).

El user-data **solo se ejecuta en el primer arranque**. Si modificas el template:

```powershell
terraform apply -replace="module.standalone_ec2[0].aws_instance.this"
```

**Logs**

```bash
sudo tail -f /var/log/user-data-docker.log
sudo cloud-init status --wait
```

En SSM la sesión suele ser `ssm-user`; para el directorio de la app: `sudo su - ec2-user`.

---

## ECS Fargate

El módulo `ecs-cluster` agrupa:

| Servicio | Contenedor | Puerto | Target group |
|----------|------------|--------|----------------|
| Backend | `flask` | 5000 | Backend (regla `/api/*`) |
| Frontend | `nextjs` | 3000 | Frontend (listener default) |

- **Launch type:** Fargate, `platform_version = LATEST`
- **Red:** subnets `private_webapp`, security group `web_app`
- **Task definitions:** definidas en `modules/ecs-fargate-service` (CPU/memoria configurables; default 512 / 1024 MiB)

---

## RDS y secretos

| Componente | Descripción |
|------------|-------------|
| **RDS** | MySQL 8, sin acceso público, en subnets de datos |
| **Secreto JSON** | Nombre tipo `ritual-roast-mysql-credentials-dev` (host, user, password, dbname, port) |
| **Rotación** | Lambda desplegada desde SAR en la VPC, si `rds_mysql_enable_secret_rotation = true` |

El rol de ejecución ECS y el rol de la EC2 pueden leer el secreto según las políticas definidas en los módulos IAM.

---

## Outputs

```text
alb_dns_name                    # URL pública de la aplicación
ecr_frontend_repository_url
ecr_backend_repository_url
ecs_cluster_name
ecs_backend_service_name
ecs_frontend_service_name
standalone_ec2_instance_id      # Conexión vía SSM
mysql_credentials_secret_name
```

Consulta la lista completa en `outputs.tf` o con `terraform output`.

---

## Orden de despliegue

1. Ejecutar `terraform apply` y esperar a que termine la creación de recursos.
2. Esperar a que la EC2 complete el user-data (imágenes visibles en ECR).
3. Verificar target groups **healthy** en el ALB.
4. Abrir `http://<alb_dns_name>`.

Si ECS despliega tareas antes de que existan imágenes en ECR, las tareas fallarán hasta que el tag configurado (p. ej. `latest`) esté disponible en ambos repositorios.

---

## Problemas frecuentes

| Síntoma | Acción sugerida |
|---------|-----------------|
| Repositorios ECR vacíos | Revisar `/var/log/user-data-docker.log` y `cloud-init status`; comprobar NAT y descarga con `curl -4` |
| `cloud-init status: error` | Log completo del user-data; recrear la instancia con `-replace` si cambió el script |
| Targets unhealthy | Logs del contenedor en CloudWatch (`/ecs/ritual-roast-*-dev`) |
| El API no responde | Regla del listener `/api/*` y health check `/api/health` |
| Cambios en user-data sin efecto | `terraform apply -replace="module.standalone_ec2[0].aws_instance.this"` |

---

## Destruir el entorno

```powershell
terraform destroy
```

En desarrollo, `ecr_force_delete = true` permite eliminar los repositorios aunque contengan imágenes. Valora este comportamiento antes de usarlo en entornos compartidos o productivos.

---

<div align="center">

[⬆️ Volver al README del proyecto](../../README.md)

</div>
