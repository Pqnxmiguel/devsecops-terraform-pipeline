output "secure_bucket_name" {
  description = "Nombre del bucket S3 seguro creado como baseline"
  value       = aws_s3_bucket.secure_bucket.id
}