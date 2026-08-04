# ============================================================
# Baseline limpio: infraestructura mínima y segura.
# Se usará como base para introducir vulnerabilidades
# controladas en PRs posteriores y validar los escáneres.
#
# Los "skip" están documentados y aplican solo a reglas de
# buenas prácticas opcionales que no aplican a este laboratorio
# (replicación cross-region, KMS custom, notificaciones, etc).
# ============================================================

resource "random_id" "suffix" {
  byte_length = 4
}

# --- Bucket S3 con configuración segura ---
# NOTA: CKV2_AWS_62, CKV2_AWS_61, CKV_AWS_144 y CKV_AWS_145 son "graph checks"
# de Checkov: no soportan supresión inline (#checkov:skip). Se silencian vía
# `skip_check` en el job sast-checkov del workflow (.github/workflows/terraform-ci.yml).
# VULN test: versioning suspendido en aws_s3_bucket_versioning (abajo) dispara
# CKV_AWS_21 / CKV2_AWS_6, que Checkov reporta sobre este bloque.
resource "aws_s3_bucket" "secure_bucket" {
  bucket = "devsecops-demo-secure-bucket-${random_id.suffix.hex}"
}

resource "aws_s3_bucket_versioning" "secure_bucket" {
  bucket = aws_s3_bucket.secure_bucket.id
  versioning_configuration {
    status = "Suspended"
  }
}

#tfsec:ignore:aws-s3-encryption-customer-key El laboratorio no usa CMK.
#trivy:ignore:AVD-AWS-0132 El laboratorio no usa CMK.
resource "aws_s3_bucket_server_side_encryption_configuration" "secure_bucket" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# VULN test: los 4 flags en false dejan el bucket potencialmente publico
# (CKV_AWS_53/54/55/56, aws-s3-block-*, AWS-0086/0087/0093).
resource "aws_s3_bucket_public_access_block" "secure_bucket" {
  bucket = aws_s3_bucket.secure_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_logging" "secure_bucket" {
  bucket        = aws_s3_bucket.secure_bucket.id
  target_bucket = aws_s3_bucket.secure_bucket.id
  target_prefix = "log/"
}