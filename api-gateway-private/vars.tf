# Basic configuration
variable "name" {
  description = "Name of the API Gateway"
  type        = string
}

variable "description" {
  description = "Description of the API Gateway"
  type        = string
  default     = "Private API Gateway"
}

variable "vpc_id" {
  description = "VPC ID where API Gateway will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the VPC endpoint (private subnets recommended)"
  type        = list(string)
}

variable "stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "dev"
}

# Security configuration
variable "allowed_security_groups" {
  description = "Security groups allowed to access the VPC endpoint"
  type        = list(string)
  default     = []
}

variable "allowed_cidrs" {
  description = "CIDR blocks allowed to access the VPC endpoint"
  type        = list(string)
  default     = []
}

# ALB configuration
variable "internal_alb_arn" {
  description = "ARN of the internal ALB"
  type        = string
}

variable "private_dns_domain" {
  description = "Domain for private hosted zone"
  type        = string
  default     = "ob.dev.payabl1.com"
}

variable "internal_alb_dns_name" {
  description = "DNS name for internal ALB in private zone"
  type        = string
  default     = "open-banking-proxy-internal.ob.dev.payabl1.com"
}

# NLB fallback configuration
variable "create_nlb_fallback" {
  description = "Create NLB fallback if Private DNS doesn't work"
  type        = bool
  default     = false
}

# API Gateway settings
variable "quota_limit" {
  description = "API Gateway quota limit per day"
  type        = number
  default     = 10000
}

variable "throttle_rate_limit" {
  description = "API Gateway throttle rate limit per second"
  type        = number
  default     = 1000
}

variable "throttle_burst_limit" {
  description = "API Gateway throttle burst limit"
  type        = number
  default     = 2000
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
