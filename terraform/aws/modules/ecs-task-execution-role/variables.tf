variable "project_name" {
  description = "Nombre del proyecto."
  type        = string
}

variable "environment" {
  description = "Entorno (dev, staging, prod)."
  type        = string
}

variable "attach_mysql_secrets_policy" {
  description = "Si es true, adjunta política GetSecretValue (count debe ser conocido en plan)."
  type        = bool
  default     = false
}

variable "mysql_secret_arn" {
  description = "ARN del secreto MySQL en Secrets Manager (GetSecretValue)."
  type        = string
  default     = null
  nullable    = true
}

variable "tags" {
  description = "Etiquetas adicionales."
  type        = map(string)
  default     = {}
}
