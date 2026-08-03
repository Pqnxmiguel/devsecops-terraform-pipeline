output "s3_bucket_name" {
  description = "Nombre del bucket creado para el backend remoto"
  value       = aws_s3_bucket.terraform_state.id
}

output "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB para el lock"
  value       = aws_dynamodb_table.terraform_locks.name
}