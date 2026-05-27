output "cluster_id" {
  description = "ID del cluster ECS."
  value       = aws_ecs_cluster.this.id
}

output "cluster_name" {
  description = "Nombre del cluster ECS."
  value       = aws_ecs_cluster.this.name
}

output "cluster_arn" {
  description = "ARN del cluster ECS."
  value       = aws_ecs_cluster.this.arn
}

output "backend_task_definition_arn" {
  description = "ARN de la task definition del backend."
  value       = try(module.service_backend[0].task_definition_arn, null)
}

output "frontend_task_definition_arn" {
  description = "ARN de la task definition del frontend."
  value       = try(module.service_frontend[0].task_definition_arn, null)
}

output "backend_service_name" {
  description = "Nombre del servicio ECS del backend."
  value       = try(module.service_backend[0].service_name, null)
}

output "frontend_service_name" {
  description = "Nombre del servicio ECS del frontend."
  value       = try(module.service_frontend[0].service_name, null)
}
