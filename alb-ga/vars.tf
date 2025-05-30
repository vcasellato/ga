variable "name" {
  description = "Name for the ALB and related resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ALB will be created"
  type        = string
}

variable "vpc_endpoint_network_interface_ids" {
  description = "Network Interface IDs from VPC Endpoint"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB (must be in different AZs)"
  type        = list(string)
  default     = null
}

variable "public_subnet_tags" {
  description = "Tags to identify public subnets for ALB (used if subnet_ids not provided)"
  type        = map(string)
  default = {
    Type = "public"
  }
}

variable "allowed_cidrs" {
  description = "CIDR blocks allowed to access ALB (Global Accelerator IPs)"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Will be restricted to GA IPs in production
}

variable "certificate_arn" {
  description = "ARN of ACM certificate for HTTPS listener"
  type        = string
  default     = null
}

variable "ssl_policy" {
  description = "SSL policy for HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS-1-2-2017-01"
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for ALB"
  type        = bool
  default     = false
}

# Access Logs
variable "enable_access_logs" {
  description = "Enable ALB access logs to S3"
  type        = bool
  default     = false
}

variable "access_logs_bucket" {
  description = "S3 bucket for ALB access logs"
  type        = string
  default     = null
}

variable "access_logs_prefix" {
  description = "S3 prefix for ALB access logs"
  type        = string
  default     = "alb-logs"
}

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch logs for ALB"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

# Health Check
variable "health_check_enabled" {
  description = "Enable health checks"
  type        = bool
  default     = true
}

variable "health_check_healthy_threshold" {
  description = "Number of consecutive health checks successes required"
  type        = number
  default     = 3
}

variable "health_check_interval" {
  description = "Approximate amount of time between health checks"
  type        = number
  default     = 30
}

variable "health_check_matcher" {
  description = "Response codes to use when checking for a healthy responses"
  type        = string
  default     = "200,403" # 403 because API Gateway returns 403 for requests without proper API key
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/"
}

variable "health_check_timeout" {
  description = "Amount of time to wait when receiving a response from the health check"
  type        = number
  default     = 10
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive health check failures required"
  type        = number
  default     = 3
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
