output "repository_name" {
  description = "Nombre del repositorio ECR."
  value       = aws_ecr_repository.this.name
}

output "repository_arn" {
  description = "ARN del repositorio ECR."
  value       = aws_ecr_repository.this.arn
}

output "repository_url" {
  description = "URL para docker push/pull (sin tag)."
  value       = aws_ecr_repository.this.repository_url
}
