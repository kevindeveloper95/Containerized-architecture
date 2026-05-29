<div align="center">

# ☁️ Infraestructura AWS

**Ritual Roast** · Terraform · entorno `dev`

<br/>

![Terraform](https://img.shields.io/badge/Terraform-844FBA?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazonwebservices&logoColor=FF9900)
![Amazon VPC](https://img.shields.io/badge/VPC-8C4FFF?style=for-the-badge&logo=amazonvpc&logoColor=white)
![ALB](https://img.shields.io/badge/ALB-8C4FFF?style=for-the-badge&logo=amazonaws&logoColor=white)
![ECS](https://img.shields.io/badge/ECS_Fargate-FF9900?style=for-the-badge&logo=amazon-ecs&logoColor=white)
![ECR](https://img.shields.io/badge/ECR-FF9900?style=for-the-badge&logo=amazon-ecr&logoColor=white)
![RDS](https://img.shields.io/badge/RDS_MySQL-527FFF?style=for-the-badge&logo=amazonrds&logoColor=white)

<br/>

[← README principal](../../README.md) ·
[📦 Qué crea](#-qué-crea-un-terraform-apply) ·
[⚙️ Variables](#️-variables-que-más-importan) ·
[🛠️ Troubleshooting](#-problemas-frecuentes)

</div>

---

Terraform que levanta la red, el balanceador, los contenedores, la base de datos y la máquina que construye las imágenes Docker. Región por defecto: **`us-east-1`** · proyecto **`ritual-roast`** · entorno **`dev`**.

🗺️ Vista general con diagrama → [README del repo](../../README.md#-arquitectura-en-aws) · `Diagram/Arquitectura-microservicios-SSA.png`

---

## 📦 Qué crea un `terraform apply`

| | Bloque | Recursos principales |
|---|--------|----------------------|
| 🌐 | **Red** | VPC `10.0.0.0/16` · subnets públicas / webapp / data · IGW · NAT |
| 🛡️ | **Seguridad** | SG ALB · SG web app · SG MySQL (+ regla self `3306`) |
| ⚖️ | **Entrada** | ALB `:80` · TG frontend `:3000` · TG backend `:5000` · regla `/api/*` |
| 🎯 | **Compute** | Cluster ECS · 2 servicios Fargate (2 tareas c/u por defecto) |
| 📦 | **Imágenes** | 2 repos ECR · EC2 build/push vía user-data |
| 🗄️ | **Datos** | RDS MySQL · Secrets Manager · rotación Lambda (opcional) |
| 🔑 | **IAM** | Rol ECS task execution · rol EC2 SSM + ECR push |

---

## 🗺️ Cómo encaja con el diagrama

Tu dibujo **Arquitectura-microservicios-SSA** y este código cuentan la misma historia:

| | Paso | En código / AWS |
|---|------|-----------------|
| 1️⃣ | **DMZ** | `module.alb` en subnets públicas |
| 2️⃣ | **Web/App** | `module.ecs_cluster` en subnets webapp |
| 3️⃣ | **Data** | `module.rds_mysql` en subnets data |
| 4️⃣ | **ECR + ECS** | `module.ecr_*` + `ecs-fargate-service` |
| 5️⃣ | **Secretos** | `mysql-credentials-secret` + Lambda rotación |
| 🏭 | **EC2 build** | `module.standalone_ec2` → llena ECR (fuera del path del usuario) |

---

## 📂 Estructura de módulos

```
terraform/aws/
├── 📄 main.tf
├── 📄 variables.tf · outputs.tf
├── 📄 terraform.tfvars.example
├── 📜 templates/ec2-docker-user-data.sh.tpl
└── modules/
    ├── 🌐 vpc/
    ├── 🛡️ security-groups/
    ├── ⚖️ alb/ · alb-target-group/
    ├── 📦 ecr-repository/
    ├── 🖥️ ec2-instance/ · ec2-ssm-role/
    ├── 🎯 ecs-cluster/ · ecs-fargate-service/
    ├── 🔑 ecs-task-execution-role/
    ├── 🗄️ db-subnet-group/ · rds-aurora-mysql/
    └── 🔐 mysql-credentials-secret/ · mysql-rotation-lambda-sar/
```

---

## ✅ Requisitos

| | Requisito |
|---|-----------|
| 🔧 | [Terraform](https://www.terraform.io/downloads) **>= 1.1** |
| ☁️ | Cuenta AWS (VPC, EC2, ECS, ECR, RDS, ALB, IAM, Secrets, Lambda) |
| 🔐 | AWS CLI configurado para la región de `terraform.tfvars` |

---

## ⚡ Uso rápido

```powershell
cd terraform/aws
terraform init          # 🆕 primera vez o tras cambiar módulos
terraform plan
terraform apply
```

📋 Copia `terraform.tfvars.example` → `terraform.tfvars`:

```hcl
aws_region   = "us-east-1"
environment  = "dev"
project_name = "ritual-roast"
vpc_cidr     = "10.0.0.0/16"

standalone_ec2_frontend_zip_url = "https://raw.githubusercontent.com/iaasacademy/..."
standalone_ec2_backend_zip_url  = "https://raw.githubusercontent.com/iaasacademy/..."
standalone_ec2_instance_type    = "t3.small"
standalone_ec2_root_volume_gb   = 40

create_mysql_credentials_secret         = true
rds_mysql_enable_secret_rotation        = true
rds_mysql_rotation_lambda_deploy_in_vpc = true
```

---

## ⚙️ Variables que más importan

| Variable | Default | Efecto |
|----------|---------|--------|
| `standalone_ec2_enable` | `true` | 🖥️ EC2 build → ECR |
| `ecr_enable` | `true` | 📦 Repos + imágenes en tasks |
| `ecs_enable` | `true` | 🎯 Cluster ECS |
| `ecs_*_desired_count` | `2` | Tareas por servicio |
| `ecs_image_tag` | `latest` | Tag en ECR/ECS |
| `standalone_ec2_build_and_push_ecr` | `true` | User-data build/push |

---

## 🔀 Flujo del tráfico (ALB)

```
👤 Cliente
   │  HTTP :80
   ▼
⚖️ Application Load Balancer (público)
   │
   ├─ 📌 /api/*  ──► 🐍 Flask TG :5000 ──► ECS backend
   │
   └─ default    ──► ⚛️ Next.js TG :3000 ──► ECS frontend
```

| Servicio | Health check |
|----------|----------------|
| ⚛️ Frontend | `GET /` |
| 🐍 Backend | `GET /api/health` |

---

## 🖥️ EC2 standalone (build)

`module.standalone_ec2` en `main.tf`:

| | Detalle |
|---|---------|
| 📍 | Subnet **private webapp** |
| 🛡️ | SG **web_app** |
| 🔑 | IAM `ec2_ssm_role` (SSM, ECR, secretos) |
| 📜 | User-data: `templates/ec2-docker-user-data.sh.tpl` |

**Secuencia del script**

1. 🌐 Esperar red (curl IPv4)
2. 🐳 Instalar Docker + unzip
3. 📥 Descargar ZIPs del curso
4. 🔧 Parchear `app.py`
5. 📤 `docker build` + `push` → ECR
6. 🎯 Opcional: `ecs-init`

> ⚠️ User-data **solo en el primer arranque**. Tras cambiar el template:

```powershell
terraform apply -replace="module.standalone_ec2[0].aws_instance.this"
```

```bash
sudo tail -f /var/log/user-data-docker.log
sudo cloud-init status --wait
```

---

## 🎯 ECS Fargate

`module.ecs-cluster` incluye:

| Servicio | Puerto | Target group |
|----------|--------|----------------|
| 🐍 **backend** | 5000 | Flask TG |
| ⚛️ **frontend** | 3000 | Next.js TG (default ALB) |

- Subnets **private webapp** · SG **web_app**
- `FARGATE` · `platform_version = LATEST`
- Task definitions en `modules/ecs-fargate-service`

---

## 🗄️ RDS y secretos

| | Componente |
|---|------------|
| 🗄️ | **RDS** MySQL 8 · subnets data · sin acceso público |
| 🔐 | Secreto JSON `ritual-roast-mysql-credentials-dev` |
| 🔄 | Rotación Lambda (SAR) si `rds_mysql_enable_secret_rotation = true` |

---

## 📤 Outputs útiles

```text
alb_dns_name                 # 🌍 Abrir en el navegador
ecr_frontend_repository_url
ecr_backend_repository_url
ecs_cluster_name
ecs_backend_service_name
ecs_frontend_service_name
standalone_ec2_instance_id   # 🔌 SSM
mysql_credentials_secret_name
```

---

## 📋 Orden recomendado (desde cero)

| | Paso |
|---|------|
| 1️⃣ | `terraform apply` |
| 2️⃣ | Esperar user-data EC2 → imágenes en ECR |
| 3️⃣ | Targets **healthy** en ALB |
| 4️⃣ | Probar `http://<alb_dns_name>` |

> ⏳ Si ECS arranca antes que ECR tenga imágenes, las tareas fallan hasta existir tag `latest`.

---

## 🛠️ Problemas frecuentes

| Síntoma | Qué revisar |
|---------|-------------|
| 📦 ECR vacío | Log EC2 · NAT · `curl -4` a GitHub |
| ❌ `cloud-init: error` | `/var/log/user-data-docker.log` |
| 💔 Targets unhealthy | CloudWatch `/ecs/ritual-roast-*-dev` |
| 🔌 API no responde | Regla `/api/*` · health `/api/health` |
| 🔄 Cambié user-data | `terraform apply -replace=...` EC2 |

---

## 💥 Destruir el entorno

```powershell
terraform destroy
```

`ecr_force_delete = true` en dev permite borrar repos con imágenes.

---

## 💻 Código de aplicación

| | Entorno | Comando |
|---|---------|---------|
| ⚛️ | Frontend local | `npm install && npm run dev` |
| 🐍 | Backend local | Python + secretos según tu setup |
| ☁️ | AWS | **ECR → ECS Fargate** (EC2 solo build) |

---

<div align="center">

[⬆️ Volver al README principal](../../README.md)

</div>
