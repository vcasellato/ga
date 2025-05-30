variable "name" {
  description = "Name of the Global Accelerator"
  type        = string
}

variable "ip_address_type" {
  description = "The IP address type (IPV4 or DUAL_STACK)"
  type        = string
  default     = "IPV4"
}

variable "enabled" {
  description = "Whether the accelerator is enabled"
  type        = bool
  default     = true
}

variable "alb_arn" {
  description = "ARN of the Application Load Balancer to use as endpoint"
  type        = string
}

variable "endpoint_group_region" {
  description = "The region where the endpoint group is located"
  type        = string
}

variable "client_affinity" {
  description = "How Global Accelerator routes traffic to endpoints (NONE or SOURCE_IP)"
  type        = string
  default     = "NONE"
}

variable "traffic_dial_percentage" {
  description = "Percentage of traffic to route to this endpoint group"
  type        = number
  default     = 100
}

variable "endpoint_weight" {
  description = "Weight of the endpoint"
  type        = number
  default     = 100
}

# Health Check Configuration
variable "health_check_interval_seconds" {
  description = "The time between health checks"
  type        = number
  default     = 30
}

variable "health_check_path" {
  description = "Path for health checks"
  type        = string
  default     = "/"
}

variable "health_check_protocol" {
  description = "Protocol for health checks (HTTP or HTTPS)"
  type        = string
  default     = "HTTP"
}

variable "health_check_port" {
  description = "Port for health checks"
  type        = number
  default     = 80
}

variable "healthy_threshold_count" {
  description = "Number of consecutive successful health checks required (threshold_count in endpoint group)"
  type        = number
  default     = 3
}

# Remove unhealthy_threshold_count - não existe no Global Accelerator

# Port Overrides
variable "port_overrides_http" {
  description = "Port overrides for HTTP listener"
  type = list(object({
    listener_port = number
    endpoint_port = number
  }))
  default = []
}

variable "port_overrides_https" {
  description = "Port overrides for HTTPS listener"
  type = list(object({
    listener_port = number
    endpoint_port = number
  }))
  default = []
}

# Flow Logs
variable "flow_logs_enabled" {
  description = "Enable flow logs for Global Accelerator"
  type        = bool
  default     = false
}

variable "flow_logs_s3_bucket" {
  description = "S3 bucket for flow logs"
  type        = string
  default     = null
}

variable "flow_logs_s3_prefix" {
  description = "S3 prefix for flow logs"
  type        = string
  default     = "flow-logs"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
