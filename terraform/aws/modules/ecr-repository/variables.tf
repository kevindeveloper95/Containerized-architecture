variable "repository_name" {
  description = "Nombre del repositorio ECR (debe ser único en la cuenta/región)."
  type        = string
}

variable "image_tag_mutability" {
  description = "MUTABLE o IMMUTABLE para los tags de imagen."
  type        = string
  default     = "MUTABLE"
}

variable "force_delete" {
  description = "Si true, permite borrar el repo aunque tenga imágenes (útil en dev)."
  type        = bool
  default     = true
}

variable "scan_on_push" {
  description = "Escaneo de vulnerabilidades al hacer push."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Etiquetas adicionales."
  type        = map(string)
  default     = {}
}
