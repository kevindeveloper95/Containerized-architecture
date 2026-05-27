variable "project_name" {
  description = "Nombre del proyecto (prefijos de recursos)."
  type        = string
}

variable "environment" {
  description = "Entorno (dev, staging, prod)."
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC del target group."
  type        = string
}

variable "name_suffix" {
  description = "Sufijo del nombre (backend, frontend) para distinguir target groups."
  type        = string
}

variable "target_port" {
  description = "Puerto HTTP de la aplicación (ej. 5000, 3000)."
  type        = number
}

variable "target_type" {
  description = "Tipo de target: ip (ECS awsvpc), instance (EC2), etc."
  type        = string
  default     = "ip"
}

variable "health_check_path" {
  description = "Ruta del health check."
  type        = string
  default     = "/"
}

variable "tags" {
  description = "Tags adicionales."
  type        = map(string)
  default     = {}
}
