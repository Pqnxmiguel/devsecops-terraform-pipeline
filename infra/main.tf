# ============================================================
# ADVERTENCIA: Este archivo contiene configuraciones INSEGURAS
# a propósito, con fines educativos, para que Checkov y tfsec
# las detecten en el pipeline. NUNCA aplicar en producción.
# ============================================================

# --- Vulnerabilidad 1: Bucket S3 sin cifrado y con ACL pública ---
resource "aws_s3_bucket" "insecure_bucket" {
  bucket = "devsecops-demo-insecure-bucket-${random_id.suffix.hex}"
}

resource "aws_s3_bucket_acl" "insecure_bucket_acl" {
  bucket = aws_s3_bucket.insecure_bucket.id
  acl    = "public-read"  # Checkov/tfsec: bucket accesible públicamente
}

resource "random_id" "suffix" {
  byte_length = 4
}

# --- Vulnerabilidad 2: Security Group abierto a todo Internet ---
resource "aws_security_group" "insecure_sg" {
  name        = "devsecops-demo-insecure-sg"
  description = "Security group inseguro para demo"

  ingress {
    description = "SSH abierto al mundo entero"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Checkov/tfsec: SSH expuesto a Internet
  }

  ingress {
    description = "RDP abierto al mundo entero"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Checkov/tfsec: RDP expuesto a Internet
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Vulnerabilidad 3: Credenciales hardcodeadas (mal ejemplo clásico) ---
resource "aws_db_instance" "insecure_db" {
  identifier          = "devsecops-demo-db"
  engine              = "mysql"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  username            = "admin"
  password            = "SuperSecret123!"  # Checkov/tfsec: secreto hardcodeado
  publicly_accessible = true               # Checkov/tfsec: DB expuesta a Internet
  skip_final_snapshot = true
}

# --- Vulnerabilidad 4: IAM policy demasiado permisiva ---
resource "aws_iam_policy" "insecure_policy" {
  name        = "devsecops-demo-insecure-policy"
  description = "Policy con permisos excesivos"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "*"        # Checkov/tfsec: permisos de administrador total
        Resource = "*"
      }
    ]
  })
}