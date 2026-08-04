# ============================================================
# ADVERTENCIA: Este archivo contiene configuraciones INSEGURAS
# a propósito, con fines educativos, para que Checkov y tfsec
# las detecten en el pipeline. NUNCA aplicar en producción.
# ============================================================

resource "random_id" "suffix" {
  byte_length = 4
}

# --- Vulnerabilidad 1: Bucket S3 público y sin cifrado ---
resource "aws_s3_bucket" "insecure_bucket" {
  bucket = "devsecops-demo-insecure-bucket-${random_id.suffix.hex}"
}

resource "aws_s3_bucket_acl" "insecure_bucket_acl" {
  bucket = aws_s3_bucket.insecure_bucket.id
  acl    = "public-read"
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
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "RDP abierto al mundo entero"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Vulnerabilidad 3: RDS con password hardcodeada y pública ---
resource "aws_db_instance" "insecure_db" {
  identifier          = "devsecops-demo-db"
  engine              = "mysql"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  username            = "admin"
  password            = "SuperSecret123!"
  publicly_accessible = true
  skip_final_snapshot = true
}

# --- Vulnerabilidad 4: IAM policy con permisos de administrador total ---
resource "aws_iam_policy" "insecure_policy" {
  name        = "devsecops-demo-insecure-policy"
  description = "Policy con permisos excesivos"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      }
    ]
  })
}

# --- Vulnerabilidad 5: Puerto de base de datos abierto a Internet ---
resource "aws_security_group_rule" "insecure_db_rule" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.insecure_sg.id
}

# --- Vulnerabilidad 6: Bucket S3 sin ningún tipo de protección ---
resource "aws_s3_bucket" "another_insecure_bucket" {
  bucket = "devsecops-demo-test-final-${random_id.suffix.hex}"
}

# --- Vulnerabilidad 7 (NUEVA): EBS volume sin cifrado ---
resource "aws_ebs_volume" "insecure_volume" {
  availability_zone = "us-east-1a"
  size              = 10
  encrypted         = false
}

# --- Vulnerabilidad 8 (NUEVA): CloudTrail deshabilitado / sin validación de logs ---
resource "aws_cloudtrail" "insecure_trail" {
  name                          = "devsecops-demo-trail"
  s3_bucket_name                = aws_s3_bucket.insecure_bucket.id
  enable_log_file_validation    = false
  is_multi_region_trail         = false
}

# --- Vulnerabilidad 9 (NUEVA): Elastic IP asociada sin restricciones ---
resource "aws_security_group" "insecure_sg_2" {
  name        = "devsecops-demo-insecure-sg-2"
  description = "Segundo security group inseguro para prueba"

  ingress {
    description = "HTTP abierto al mundo entero"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Puerto de administracion abierto"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}