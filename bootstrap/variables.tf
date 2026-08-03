variable "aws_region" {
  description = "Región de AWS donde se crea la infraestructura de backend"
  type        = string
  default     = "us-east-2"
}

variable "bucket_name" {
  description = "Nombre del bucket S3 para el Terraform state (debe ser único globalmente en AWS)"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB para el state lock"
  type        = string
  default     = "terraform-locks-devsecops"
}