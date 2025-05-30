variable "name_prefix" {
  description = "Prefix for the bucket name"
  type        = string
}

variable "bucket_name" {
  description = "Specific bucket name (optional, will generate if not provided)"
  type        = string
  default     = null
}

variable "versioning_enabled" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for S3 encryption (optional)"
  type        = string
  default     = null
}

variable "allow_global_accelerator_logs" {
  description = "Allow Global Accelerator to write logs to this bucket"
  type        = bool
  default     = true
}

variable "lifecycle_rules" {
  description = "S3 lifecycle rules"
  type = list(object({
    id                                    = string
    status                               = string
    expiration_days                      = optional(number)
    noncurrent_version_expiration_days   = optional(number)
    transitions = optional(list(object({
      days          = number
      storage_class = string
    })))
  }))
  default = []
}

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch log group for S3 monitoring"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
