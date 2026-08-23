# ============================================================
# Baseline limpio: infraestructura mínima y segura.
# Se usará como base para introducir vulnerabilidades
# controladas en PRs posteriores y validar los escáneres.
#
# Los "skip" están documentados y aplican solo a reglas de
# buenas prácticas opcionales que no aplican a este laboratorio
# (replicación cross-region, KMS custom, notificaciones, etc).
#
# Demo: esta rama (main) se mantiene limpia (0 hallazgos) a proposito,
# como contraste con test/vulnerabilidades-s3-final (vulnerabilidades
# introducidas a proposito para validar checkov/tfsec/trivy).
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

# VULN test: block_public_acls en false deja el bucket potencialmente publico
# (CKV_AWS_53, aws-s3-block-public-acls, AWS-0086). Se deja un solo flag en
# false (no los 4) para que Checkov reporte una unica regla sobre este bloque:
# si varias reglas de Checkov comparten la misma region, GitHub les genera el
# mismo fingerprint y no las cuenta como alertas nuevas del PR.
resource "aws_s3_bucket_public_access_block" "secure_bucket" { # vuln-test: linea tocada a proposito
  bucket = aws_s3_bucket.secure_bucket.id

  block_public_acls       = false
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "secure_bucket" {
  bucket        = aws_s3_bucket.secure_bucket.id
  target_bucket = aws_s3_bucket.secure_bucket.id
  target_prefix = "log/"
}