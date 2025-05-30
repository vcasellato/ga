variable "name" {
  description = "Name prefix for VPC Endpoint resources"
  type        = string
}

variable "description" {
  description = "Description for the API Gateway"
  type        = string
  default     = "Private API Gateway with VPC Link"
}

variable "vpc_id" {
  description = "VPC ID where the endpoint will be created"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the VPC endpoint (private subnets recommended)"
  type        = list(string)
}

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

variable "private_dns_enabled" {
  description = "Enable private DNS for the VPC endpoint"
  type        = bool
  default     = true
}

variable "endpoint_policy" {
  description = "Custom policy for the VPC endpoint (JSON string)"
  type        = string
  default     = null
}

variable "internal_alb_name" {
  description = "Name of the internal ALB"
  type        = string
  default     = "internal-k8s-backend-openbank-3eb2968814"
}

variable "stage_name" {
  description = "Stage name for API Gateway deployment"
  type        = string
  default     = "dev"
}

variable "quota_limit" {
  description = "API quota limit per day"
  type        = number
  default     = 10000
}

variable "throttle_rate_limit" {
  description = "API throttle rate limit"
  type        = number
  default     = 1000
}

variable "throttle_burst_limit" {
  description = "API throttle burst limit"
  type        = number
  default     = 2000
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
