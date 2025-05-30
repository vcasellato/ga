output "bucket_id" {
  description = "ID of the S3 bucket"
  value       = aws_s3_bucket.flow_logs.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.flow_logs.arn
}

output "bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.flow_logs.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  value       = aws_s3_bucket.flow_logs.bucket_regional_domain_name
}

output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.flow_logs.bucket
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group (if created)"
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.s3_access_logs[0].name : null
}
