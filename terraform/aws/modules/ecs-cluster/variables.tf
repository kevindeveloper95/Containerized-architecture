variable "cluster_name" {
  description = "Nombre del cluster ECS."
  type        = string
}

variable "create_services" {
  description = "Si es true, crea los servicios Fargate frontend y backend en este cluster."
  type        = bool
  default     = false
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "vpc_id" {
  description = "VPC del cluster y de las tareas Fargate."
  type        = string
}

variable "private_subnet_ids" {
  description = "Subnets privadas webapp para las tareas."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups de webapp para las tareas."
  type        = list(string)
}

variable "execution_role_arn" {
  description = "Rol de ejecución ECS (pull ECR, logs, secretos)."
  type        = string
  default     = null
  nullable    = true
}

variable "backend_container_image" {
  type    = string
  default = ""
}

variable "frontend_container_image" {
  type    = string
  default = ""
}

variable "backend_target_group_arn" {
  type    = string
  default = null
  nullable = true
}

variable "frontend_target_group_arn" {
  type    = string
  default = null
  nullable = true
}

variable "backend_desired_count" {
  type    = number
  default = 2
}

variable "frontend_desired_count" {
  type    = number
  default = 2
}

variable "backend_task_cpu" {
  type    = string
  default = "512"
}

variable "backend_task_memory" {
  type    = string
  default = "1024"
}

variable "frontend_task_cpu" {
  type    = string
  default = "512"
}

variable "frontend_task_memory" {
  type    = string
  default = "1024"
}

variable "tags" {
  description = "Etiquetas adicionales."
  type        = map(string)
  default     = {}
}
