variable "project_name" {
  type        = string
  description = "Nombre del proyecto."
}

variable "environment" {
  type        = string
  description = "Entorno (dev, staging, prod)."
}

variable "instance_type" {
  type        = string
  description = "Tipo de instancia EC2."
}

variable "subnet_id" {
  type        = string
  description = "Subnet donde lanzar la instancia."
}

variable "vpc_security_group_ids" {
  type        = list(string)
  description = "Security groups de la instancia."
}

variable "iam_instance_profile_name" {
  type        = string
  description = "Nombre del instance profile IAM (rol EC2 SSM)."
}

variable "user_data_base64" {
  type        = string
  description = "User data en base64 (opcional)."
  default     = null
  nullable    = true
}

variable "root_volume_gb" {
  type        = number
  description = "Tamaño del volumen raíz EBS (GiB)."
  default     = 20
}

variable "tags" {
  type        = map(string)
  description = "Etiquetas adicionales."
  default     = {}
}
