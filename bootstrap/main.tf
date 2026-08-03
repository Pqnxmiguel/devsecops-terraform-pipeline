terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Bucket S3 donde vivirá el terraform.tfstate del proyecto principal
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.bucket_name

  # Protección: evita que 'terraform destroy' borre este bucket por accidente
  lifecycle {
    prevent_destroy = true
  }
}

# Versionado: si el state se corrompe, podemos volver a una versión anterior
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Cifrado en reposo: el state puede contener datos sensibles (IDs, IPs, etc.)
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bloquea CUALQUIER acceso público al bucket (buena práctica de seguridad)
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Tabla DynamoDB para el "lock" del state (evita que 2 personas apliquen a la vez)
resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"  # Sin costo fijo, pagas solo por uso (y aquí es ~$0)
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}