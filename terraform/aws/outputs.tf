
output "vpc_id" {
  description = "ID de la VPC."
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR de la VPC."
  value       = module.vpc.vpc_cidr_block
}

output "private_webapp_subnet_ids" {
  description = "IDs de subnets privadas webapp (EC2, ECS, EKS)."
  value = [
    module.vpc.private_webapp_subnet_1_id,
    module.vpc.private_webapp_subnet_2_id,
  ]
}

output "private_data_subnet_ids" {
  description = "IDs de subnets privadas capa datos (RDS, ElastiCache, Lambda rotación)."
  value = [
    module.vpc.private_data_subnet_1_id,
    module.vpc.private_data_subnet_2_id,
  ]
}

output "public_subnet_ids" {
  description = "IDs de subnets públicas."
  value = [
    module.vpc.public_subnet_1_id,
    module.vpc.public_subnet_2_id,
  ]
}

output "web_app_security_group_id" {
  description = "ID del security group de la web app."
  value       = module.security_groups.web_app_security_group_id
}

output "alb_security_group_id" {
  description = "ID del security group del Application Load Balancer."
  value       = module.security_groups.alb_security_group_id
}

output "alb_dns_name" {
  description = "DNS público del Application Load Balancer (listener :80 → target group Next.js :3000)."
  value       = module.alb.alb_dns_name
}

output "alb_default_target_group_arn" {
  description = "ARN del target group asociado al listener HTTP (frontend Next.js)."
  value       = module.alb_target_group_frontend.arn
}

output "alb_arn" {
  description = "ARN del Application Load Balancer."
  value       = module.alb.alb_arn
}

output "alb_target_group_backend_arn" {
  description = "ARN del target group Flask (puerto 5000, target_type ip)."
  value       = module.alb_target_group_backend.arn
}

output "alb_target_group_backend_name" {
  description = "Nombre del target group backend."
  value       = module.alb_target_group_backend.name
}

output "alb_target_group_frontend_arn" {
  description = "ARN del target group Next.js (puerto 3000, target_type ip)."
  value       = module.alb_target_group_frontend.arn
}

output "alb_target_group_frontend_name" {
  description = "Nombre del target group frontend."
  value       = module.alb_target_group_frontend.name
}

output "ec2_ssm_role_name" {
  description = "Nombre del rol IAM para EC2 con acceso a Systems Manager."
  value       = module.ec2_ssm_role.role_name
}

output "ec2_ssm_role_arn" {
  description = "ARN del rol IAM para EC2 con acceso a Systems Manager."
  value       = module.ec2_ssm_role.role_arn
}

output "ec2_instance_profile_name" {
  description = "Nombre del instance profile para asociar a la EC2."
  value       = module.ec2_ssm_role.instance_profile_name
}

output "standalone_ec2_instance_id" {
  description = "ID de la instancia EC2 suelta (si standalone_ec2_enable = true)."
  value       = try(module.standalone_ec2[0].instance_id, null)
}

output "standalone_ec2_private_ip" {
  description = "IP privada de la instancia EC2 suelta."
  value       = try(module.standalone_ec2[0].private_ip, null)
}

output "standalone_ec2_private_dns" {
  description = "DNS privado de la instancia EC2 suelta (Session Manager / conexión interna)."
  value       = try(module.standalone_ec2[0].private_dns, null)
}

output "ecs_task_execution_role_name" {
  description = "Nombre del rol IAM de ejecución de tareas ECS (task execution role)."
  value       = module.ecs_task_execution_role.role_name
}

output "ecs_task_execution_role_arn" {
  description = "ARN del rol IAM de ejecución de tareas ECS."
  value       = module.ecs_task_execution_role.role_arn
}

output "ecs_cluster_name" {
  description = "Nombre del cluster ECS Fargate."
  value       = try(module.ecs_cluster[0].cluster_name, null)
}

output "ecs_cluster_arn" {
  description = "ARN del cluster ECS."
  value       = try(module.ecs_cluster[0].cluster_arn, null)
}

output "ecs_backend_task_definition_arn" {
  description = "ARN de la task definition del backend Flask."
  value       = try(module.ecs_cluster[0].backend_task_definition_arn, null)
}

output "ecs_frontend_task_definition_arn" {
  description = "ARN de la task definition del frontend Next.js."
  value       = try(module.ecs_cluster[0].frontend_task_definition_arn, null)
}

output "ecs_backend_service_name" {
  description = "Nombre del servicio ECS del backend."
  value       = try(module.ecs_cluster[0].backend_service_name, null)
}

output "ecs_frontend_service_name" {
  description = "Nombre del servicio ECS del frontend."
  value       = try(module.ecs_cluster[0].frontend_service_name, null)
}

output "ecr_frontend_repository_url" {
  description = "URL del repositorio ECR del frontend (Next.js)."
  value       = try(module.ecr_frontend[0].repository_url, null)
}

output "ecr_frontend_repository_arn" {
  description = "ARN del repositorio ECR del frontend."
  value       = try(module.ecr_frontend[0].repository_arn, null)
}

output "ecr_backend_repository_url" {
  description = "URL del repositorio ECR del backend (Flask)."
  value       = try(module.ecr_backend[0].repository_url, null)
}

output "ecr_backend_repository_arn" {
  description = "ARN del repositorio ECR del backend."
  value       = try(module.ecr_backend[0].repository_arn, null)
}

output "rds_mysql_master_user_secret_arn" {
  description = "ARN del secreto maestro gestionado por RDS (solo si rds_mysql_password es null y rds_mysql_enable_secret_rotation es false)."
  value       = try(module.rds_mysql.master_user_secret_arn, null)
}

output "rds_mysql_credentials_secret_name" {
  description = "Nombre del secreto JSON para la app EC2 y rotación Lambda (GetSecretValue por nombre)."
  value       = local.mysql_credentials_secret_name != "" ? local.mysql_credentials_secret_name : null
}

output "rds_mysql_rotation_secret_arn" {
  description = "ARN del secreto JSON rotado por Lambda cuando rds_mysql_enable_secret_rotation es true (mysql-credentials o mysql-rotation según flags)."
  value = var.rds_mysql_enable_secret_rotation ? (
    var.create_mysql_credentials_secret ? module.mysql_credentials_secret[0].secret_arn : module.mysql_rotation_only_secret[0].secret_arn
  ) : null
}

output "rds_mysql_secret_rotation_lambda_arn" {
  description = "Lambda usada para rotar el secreto JSON maestro (solo si rds_mysql_enable_secret_rotation es true)."
  value       = try(module.rds_mysql_master_secret_rotation[0].rotation_lambda_arn_effective, null)
}

output "rds_mysql_rotation_sar_stack_name" {
  description = "Nombre del stack CloudFormation del SAR de rotación MySQL (si se desplegó en VPC)."
  value       = try(module.mysql_rotation_sar_lambda[0].cloudformation_stack_name, null)
}
