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
# checkov:skip=CKV2_AWS_62: No se requieren event notifications en este laboratorio.
# checkov:skip=CKV2_AWS_61: Lifecycle no aplica; el bucket es efímero de demo.
# checkov:skip=CKV_AWS_144: Replicación cross-region no aplica al laboratorio.
# checkov:skip=CKV_AWS_145: Se usa AES256 gestionado por AWS, no KMS custom.
#tfsec:ignore:aws-s3-encryption-customer-key El laboratorio no usa CMK.
#trivy:ignore:AVD-AWS-0132 El laboratorio no usa CMK.
resource "aws_s3_bucket" "secure_bucket" {
  bucket = "devsecops-demo-secure-bucket-${random_id.suffix.hex}"
}

resource "aws_s3_bucket_versioning" "secure_bucket" {
  bucket = aws_s3_bucket.secure_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "secure_bucket" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "secure_bucket" {
  bucket = aws_s3_bucket.secure_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "secure_bucket" {
  bucket        = aws_s3_bucket.secure_bucket.id
  target_bucket = aws_s3_bucket.secure_bucket.id
  target_prefix = "log/"
}