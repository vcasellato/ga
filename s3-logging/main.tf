# Random suffix for bucket name uniqueness
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 bucket for Global Accelerator flow logs
resource "aws_s3_bucket" "flow_logs" {
  bucket = var.bucket_name != null ? var.bucket_name : "${var.name_prefix}-flow-logs-${random_id.bucket_suffix.hex}"

  tags = var.tags
}

# Bucket versioning
resource "aws_s3_bucket_versioning" "flow_logs" {
  bucket = aws_s3_bucket.flow_logs.id
  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Disabled"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "flow_logs" {
  bucket = aws_s3_bucket.flow_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_id != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_id
    }
    bucket_key_enabled = var.kms_key_id != null
  }
}

# Bucket lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "flow_logs" {
  count  = length(var.lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.flow_logs.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.status

      dynamic "expiration" {
        for_each = rule.value.expiration_days != null ? [1] : []
        content {
          days = rule.value.expiration_days
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration_days != null ? [1] : []
        content {
          noncurrent_days = rule.value.noncurrent_version_expiration_days
        }
      }

      dynamic "transition" {
        for_each = rule.value.transitions != null ? rule.value.transitions : []
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }
    }
  }
}

# Bucket public access block (security best practice)
resource "aws_s3_bucket_public_access_block" "flow_logs" {
  bucket = aws_s3_bucket.flow_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket policy for Global Accelerator (allows GA to write logs)
resource "aws_s3_bucket_policy" "flow_logs" {
  count  = var.allow_global_accelerator_logs ? 1 : 0
  bucket = aws_s3_bucket.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSGlobalAcceleratorDeliverLogs"
        Effect = "Allow"
        Principal = {
          Service = "globalaccelerator.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.flow_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid    = "AWSGlobalAcceleratorGetBucketAcl"
        Effect = "Allow"
        Principal = {
          Service = "globalaccelerator.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.flow_logs.arn
      }
    ]
  })
}

# Optional: CloudWatch log group for S3 access logs (monitoring)
resource "aws_cloudwatch_log_group" "s3_access_logs" {
  count             = var.enable_cloudwatch_logs ? 1 : 0
  name              = "/aws/s3/${aws_s3_bucket.flow_logs.bucket}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}
