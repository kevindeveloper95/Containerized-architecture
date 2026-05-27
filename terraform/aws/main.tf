terraform {
  required_version = ">= 1.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  # Contraseña maestra: generada por random_password o rds_mysql_password según flags de secretos/rotación.
  rds_master_password_effective = var.create_mysql_credentials_secret ? (
    var.rds_mysql_password != null ? var.rds_mysql_password : random_password.mysql_credentials[0].result
    ) : (
    var.rds_mysql_enable_secret_rotation ? (
      var.rds_mysql_password != null ? var.rds_mysql_password : random_password.mysql_rotation_only[0].result
    ) : var.rds_mysql_password
  )

  # Nombre fijo del secreto JSON para EC2 y Lambda (el ARN lleva sufijo aleatorio de AWS).
  mysql_credentials_secret_name = var.create_mysql_credentials_secret ? "${var.project_name}-mysql-credentials-${var.environment}" : (
    var.rds_mysql_enable_secret_rotation ? "${var.project_name}-mysql-rotation-${var.environment}" : ""
  )

  # Secreto maestro rds!db-* de RDS solo si no hay contraseña en Terraform (sin rotación/credenciales propias).
  rds_use_managed_master_password = local.rds_master_password_effective == null

  ecs_cluster_name = trimspace(var.ecs_cluster_name) != "" ? trimspace(var.ecs_cluster_name) : "${var.project_name}-${var.environment}"

  private_webapp_subnet_ids = [
    module.vpc.private_webapp_subnet_1_id,
    module.vpc.private_webapp_subnet_2_id,
  ]

  ecs_backend_image  = var.ecr_enable ? "${module.ecr_backend[0].repository_url}:${var.ecs_image_tag}" : ""
  ecs_frontend_image = var.ecr_enable ? "${module.ecr_frontend[0].repository_url}:${var.ecs_image_tag}" : ""
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "random_password" "mysql_credentials" {
  count = var.create_mysql_credentials_secret && var.rds_mysql_password == null ? 1 : 0

  length  = 24
  special = false
}

resource "random_password" "mysql_rotation_only" {
  count = var.rds_mysql_enable_secret_rotation && !var.create_mysql_credentials_secret && var.rds_mysql_password == null ? 1 : 0

  length  = 24
  special = false
}

module "ec2_ssm_role" {
  source = "./modules/ec2-ssm-role"

  project_name = var.project_name
  environment  = var.environment

  aws_region     = var.aws_region
  aws_account_id = data.aws_caller_identity.current.account_id

  secretsmanager_extra_secret_arns = var.ec2_secretsmanager_extra_arns

  ecr_repository_arns = var.ecr_enable ? [
    "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${var.project_name}-frontend-${var.environment}",
    "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${var.project_name}-backend-${var.environment}",
  ] : []

  tags = {
    Name = "${var.project_name}-ec2-ssm-role-${var.environment}"
  }
}

module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = data.aws_availability_zones.available.names

  tags = {
    Name = "${var.project_name}-vpc-${var.environment}"
  }
}

module "security_groups" {
  source = "./modules/security-groups"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id

  tags = {
    Name = "${var.project_name}-security-groups-${var.environment}"
  }
}

module "ecr_frontend" {
  count = var.ecr_enable ? 1 : 0

  source = "./modules/ecr-repository"

  repository_name      = "${var.project_name}-frontend-${var.environment}"
  force_delete         = var.ecr_force_delete
  image_tag_mutability = "MUTABLE"
  scan_on_push         = true

  tags = {
    Name = "${var.project_name}-frontend-${var.environment}"
    App  = "nextjs"
  }
}

module "ecr_backend" {
  count = var.ecr_enable ? 1 : 0

  source = "./modules/ecr-repository"

  repository_name      = "${var.project_name}-backend-${var.environment}"
  force_delete         = var.ecr_force_delete
  image_tag_mutability = "MUTABLE"
  scan_on_push         = true

  tags = {
    Name = "${var.project_name}-backend-${var.environment}"
    App  = "flask"
  }
}

module "standalone_ec2" {
  count = var.standalone_ec2_enable ? 1 : 0

  source = "./modules/ec2-instance"

  project_name = var.project_name
  environment  = var.environment

  instance_type          = var.standalone_ec2_instance_type
  subnet_id              = module.vpc.private_webapp_subnet_1_id
  vpc_security_group_ids = [module.security_groups.web_app_security_group_id]

  iam_instance_profile_name = module.ec2_ssm_role.instance_profile_name
  root_volume_gb            = var.standalone_ec2_root_volume_gb

  user_data_base64 = base64encode(templatefile("${path.module}/templates/ec2-docker-user-data.sh.tpl", {
    install_ecs_agent         = var.standalone_ec2_install_ecs_agent
    ecs_cluster_name          = trimspace(var.standalone_ec2_ecs_cluster_name) != "" ? trimspace(var.standalone_ec2_ecs_cluster_name) : local.ecs_cluster_name
    app_base_dir              = var.standalone_ec2_app_base_dir
    aws_region                = var.aws_region
    frontend_zip_url          = trimspace(var.standalone_ec2_frontend_zip_url)
    backend_zip_url           = trimspace(var.standalone_ec2_backend_zip_url)
    frontend_dir_name         = var.standalone_ec2_frontend_dir_name
    backend_dir_name          = var.standalone_ec2_backend_dir_name
    docker_image_tag          = var.standalone_ec2_docker_image_tag
    mysql_secret_id           = local.mysql_credentials_secret_name
    build_and_push_ecr_images = var.standalone_ec2_build_and_push_ecr && var.ecr_enable
    ecr_registry              = var.ecr_enable ? split("/", module.ecr_frontend[0].repository_url)[0] : ""
    frontend_ecr_image_uri    = var.ecr_enable ? "${module.ecr_frontend[0].repository_url}:${var.standalone_ec2_docker_image_tag}" : ""
    backend_ecr_image_uri     = var.ecr_enable ? "${module.ecr_backend[0].repository_url}:${var.standalone_ec2_docker_image_tag}" : ""
  }))

  tags = {
    Name = "${var.project_name}-standalone-ec2-${var.environment}"
  }

  depends_on = [
    module.vpc,
    module.security_groups,
    module.ec2_ssm_role,
    module.ecr_frontend,
    module.ecr_backend,
  ]
}

module "alb_target_group_backend" {
  source = "./modules/alb-target-group"

  project_name      = var.project_name
  environment       = var.environment
  name_suffix       = "backend"
  vpc_id            = module.vpc.vpc_id
  target_port       = 5000
  target_type       = "ip"
  health_check_path = "/api/health"

  tags = {
    Name = "${var.project_name}-backend-tg-${var.environment}"
    App  = "flask"
  }
}

module "alb_target_group_frontend" {
  source = "./modules/alb-target-group"

  project_name      = var.project_name
  environment       = var.environment
  name_suffix       = "frontend"
  vpc_id            = module.vpc.vpc_id
  target_port       = 3000
  target_type       = "ip"
  health_check_path = "/"

  tags = {
    Name = "${var.project_name}-frontend-tg-${var.environment}"
    App  = "nextjs"
  }
}

module "alb" {
  source = "./modules/alb"

  project_name       = var.project_name
  environment        = var.environment
  public_subnet_ids  = [module.vpc.public_subnet_1_id, module.vpc.public_subnet_2_id]
  security_group_ids = [module.security_groups.alb_security_group_id]
  target_group_arn   = module.alb_target_group_frontend.arn
  listener_http_port = 80

  tags = {
    Name = "${var.project_name}-alb-${var.environment}"
  }

  depends_on = [
    module.alb_target_group_frontend,
    module.alb_target_group_backend,
  ]
}

resource "aws_lb_listener_rule" "backend_api" {
  listener_arn = module.alb.listener_http_arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = module.alb_target_group_backend.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

module "db_subnet_group" {
  source = "./modules/db-subnet-group"

  project_name = var.project_name
  environment  = var.environment
  subnet_ids = [
    module.vpc.private_data_subnet_1_id,
    module.vpc.private_data_subnet_2_id,
  ]

  tags = {
    Name = "${var.project_name}-db-subnet-group-${var.environment}"
  }
}

# Rotación MySQL en VPC vía SAR cuando no se indica rds_mysql_secret_rotation_lambda_arn.
module "mysql_rotation_sar_lambda" {
  count = var.rds_mysql_enable_secret_rotation && trimspace(var.rds_mysql_secret_rotation_lambda_arn) == "" && var.rds_mysql_rotation_lambda_deploy_in_vpc ? 1 : 0

  source = "./modules/mysql-rotation-lambda-sar"

  project_name             = var.project_name
  environment              = var.environment
  aws_region               = var.aws_region
  lambda_security_group_id = module.security_groups.mysql_security_group_id
  private_subnet_ids = [
    module.vpc.private_data_subnet_1_id,
    module.vpc.private_data_subnet_2_id,
  ]

  tags = {
    Name = "${var.project_name}-mysql-rotation-sar-${var.environment}"
  }
}

module "rds_mysql" {
  source = "./modules/rds-aurora-mysql"

  project_name            = var.project_name
  environment             = var.environment
  database_name           = var.rds_mysql_database_name
  master_username               = var.rds_mysql_username
  master_password               = local.rds_master_password_effective
  manage_master_user_password = local.rds_use_managed_master_password
  instance_class              = var.rds_mysql_instance_class
  allocated_storage       = var.rds_mysql_allocated_storage
  multi_az                = var.rds_mysql_multi_az
  db_subnet_group_name    = module.db_subnet_group.db_subnet_group_name
  mysql_security_group_id = module.security_groups.mysql_security_group_id

  tags = {
    Name = "${var.project_name}-mysql-${var.environment}"
  }
}

module "mysql_credentials_secret" {
  count = var.create_mysql_credentials_secret ? 1 : 0

  source = "./modules/mysql-credentials-secret"

  project_name = var.project_name
  environment  = var.environment

  db_host     = module.rds_mysql.db_instance_address
  db_port     = module.rds_mysql.db_instance_port
  db_database = var.rds_mysql_database_name
  db_username = var.rds_mysql_username
  db_password = local.rds_master_password_effective

  tags = {
    Name = "${var.project_name}-mysql-credentials-${var.environment}"
  }

  depends_on = [module.rds_mysql]
}

# Secreto JSON solo para rotación si create_mysql_credentials_secret es false.
module "mysql_rotation_only_secret" {
  count = var.rds_mysql_enable_secret_rotation && !var.create_mysql_credentials_secret ? 1 : 0

  source = "./modules/mysql-credentials-secret"

  project_name      = var.project_name
  environment       = var.environment
  secret_name_slug  = "mysql-rotation"
  db_host           = module.rds_mysql.db_instance_address
  db_port           = module.rds_mysql.db_instance_port
  db_database       = var.rds_mysql_database_name
  db_username       = var.rds_mysql_username
  db_password       = local.rds_master_password_effective

  tags = {
    Name = "${var.project_name}-mysql-rotation-${var.environment}"
  }

  depends_on = [module.rds_mysql]
}

module "ecs_task_execution_role" {
  source = "./modules/ecs-task-execution-role"

  project_name = var.project_name
  environment  = var.environment

  attach_mysql_secrets_policy = var.create_mysql_credentials_secret || (
    var.rds_mysql_enable_secret_rotation && !var.create_mysql_credentials_secret
  )

  mysql_secret_arn = var.create_mysql_credentials_secret ? module.mysql_credentials_secret[0].secret_arn : (
    var.rds_mysql_enable_secret_rotation && !var.create_mysql_credentials_secret ? module.mysql_rotation_only_secret[0].secret_arn : null
  )

  tags = {
    Name = "${var.project_name}-ecs-task-exec-role-${var.environment}"
  }

  depends_on = [
    module.mysql_credentials_secret,
    module.mysql_rotation_only_secret,
  ]
}

module "ecs_cluster" {
  count = var.ecs_enable ? 1 : 0

  source = "./modules/ecs-cluster"

  cluster_name    = local.ecs_cluster_name
  create_services = var.ecr_enable

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  vpc_id               = module.vpc.vpc_id
  private_subnet_ids   = local.private_webapp_subnet_ids
  security_group_ids   = [module.security_groups.web_app_security_group_id]
  execution_role_arn   = module.ecs_task_execution_role.role_arn

  backend_container_image  = local.ecs_backend_image
  frontend_container_image = local.ecs_frontend_image

  backend_target_group_arn  = module.alb_target_group_backend.arn
  frontend_target_group_arn = module.alb_target_group_frontend.arn

  backend_desired_count  = var.ecs_backend_desired_count
  frontend_desired_count = var.ecs_frontend_desired_count

  backend_task_cpu    = var.ecs_backend_task_cpu
  backend_task_memory = var.ecs_backend_task_memory
  frontend_task_cpu   = var.ecs_frontend_task_cpu
  frontend_task_memory = var.ecs_frontend_task_memory

  tags = {
    Name = local.ecs_cluster_name
  }

  depends_on = [
    module.ecs_task_execution_role,
    module.alb,
    module.alb_target_group_backend,
    module.alb_target_group_frontend,
    aws_lb_listener_rule.backend_api,
  ]
}

# Rotación Lambda sobre el secreto JSON propio (no el rds!db-* de RDS).
module "rds_mysql_master_secret_rotation" {
  count = var.rds_mysql_enable_secret_rotation ? 1 : 0

  source = "./modules/rds-mysql-master-secret-rotation"

  secret_id = var.create_mysql_credentials_secret ? module.mysql_credentials_secret[0].secret_arn : module.mysql_rotation_only_secret[0].secret_arn

  aws_region               = var.aws_region
  automatically_after_days = var.rds_mysql_secret_rotation_days
  rotation_lambda_arn = trimspace(var.rds_mysql_secret_rotation_lambda_arn) != "" ? trimspace(var.rds_mysql_secret_rotation_lambda_arn) : (
    length(module.mysql_rotation_sar_lambda) > 0 ? module.mysql_rotation_sar_lambda[0].rotation_lambda_arn : ""
  )

  depends_on = [
    module.rds_mysql,
    module.mysql_rotation_sar_lambda,
    module.mysql_credentials_secret,
    module.mysql_rotation_only_secret,
  ]
}

