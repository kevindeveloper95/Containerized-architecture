output "role_name" {
  description = "Nombre del rol de ejecución de tareas ECS."
  value       = aws_iam_role.this.name
}

output "role_arn" {
  description = "ARN del rol de ejecución de tareas ECS."
  value       = aws_iam_role.this.arn
}

output "role_id" {
  description = "ID del rol de ejecución de tareas ECS."
  value       = aws_iam_role.this.id
}
