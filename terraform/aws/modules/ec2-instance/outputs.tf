output "instance_id" {
  description = "ID de la instancia EC2."
  value       = aws_instance.this.id
}

output "instance_arn" {
  description = "ARN de la instancia EC2."
  value       = aws_instance.this.arn
}

output "private_ip" {
  description = "IP privada de la instancia."
  value       = aws_instance.this.private_ip
}

output "private_dns" {
  description = "DNS privado de la instancia."
  value       = aws_instance.this.private_dns
}

output "availability_zone" {
  description = "Zona de disponibilidad de la instancia."
  value       = aws_instance.this.availability_zone
}
