variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "app_name" {
  description = "Nombre corto de la app (backend, frontend)."
  type        = string
}

variable "container_name" {
  description = "Nombre del contenedor en la task definition."
  type        = string
}

variable "container_image" {
  description = "URI completa de la imagen ECR (repo:tag)."
  type        = string
}

variable "container_port" {
  description = "Puerto expuesto por el contenedor."
  type        = number
}

variable "aws_region" {
  type = string
}

variable "vpc_id" {
  description = "VPC donde corren las tareas (subnets deben pertenecer a esta VPC)."
  type        = string
}

variable "cluster_id" {
  type = string
}

variable "execution_role_arn" {
  description = "Rol de ejecución ECS (pull ECR, logs)."
  type        = string
}

variable "task_role_arn" {
  description = "Rol de la tarea (runtime). Vacío = sin task role."
  type        = string
  default     = null
  nullable    = true
}

variable "task_cpu" {
  type    = string
  default = "256"
}

variable "task_memory" {
  type    = string
  default = "512"
}

variable "desired_count" {
  description = "Número de tareas Fargate en ejecución."
  type        = number
  default     = 2
}

variable "platform_version" {
  description = "Versión de plataforma Fargate (LATEST recomendado)."
  type        = string
  default     = "LATEST"
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "target_group_arn" {
  description = "ARN del target group del ALB (frontend :3000 o backend :5000)."
  type        = string
}

variable "log_retention_in_days" {
  type    = number
  default = 7
}

variable "tags" {
  type    = map(string)
  default = {}
}
