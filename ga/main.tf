# Global Accelerator
resource "aws_globalaccelerator_accelerator" "main" {
  name            = var.name
  ip_address_type = var.ip_address_type
  enabled         = var.enabled

  attributes {
    flow_logs_enabled   = var.flow_logs_enabled
    flow_logs_s3_bucket = var.flow_logs_s3_bucket
    flow_logs_s3_prefix = var.flow_logs_s3_prefix
  }

  tags = var.tags
}

# HTTP Listener
resource "aws_globalaccelerator_listener" "http" {
  accelerator_arn = aws_globalaccelerator_accelerator.main.id
  client_affinity = var.client_affinity
  protocol        = "TCP"

  port_range {
    from_port = 80
    to_port   = 80
  }
}

# HTTPS Listener
resource "aws_globalaccelerator_listener" "https" {
  accelerator_arn = aws_globalaccelerator_accelerator.main.id
  client_affinity = var.client_affinity
  protocol        = "TCP"

  port_range {
    from_port = 443
    to_port   = 443
  }
}

# Endpoint Group for HTTP
resource "aws_globalaccelerator_endpoint_group" "http" {
  listener_arn = aws_globalaccelerator_listener.http.id

  endpoint_group_region         = var.endpoint_group_region
  traffic_dial_percentage       = var.traffic_dial_percentage
  health_check_interval_seconds = var.health_check_interval_seconds
  health_check_path             = var.health_check_path
  health_check_protocol         = var.health_check_protocol
  health_check_port             = var.health_check_port
  threshold_count               = var.healthy_threshold_count

  endpoint_configuration {
    endpoint_id = var.alb_arn
    weight      = var.endpoint_weight
  }

  # Port overrides for HTTP
  dynamic "port_override" {
    for_each = var.port_overrides_http
    content {
      listener_port = port_override.value.listener_port
      endpoint_port = port_override.value.endpoint_port
    }
  }
}

# Endpoint Group for HTTPS
resource "aws_globalaccelerator_endpoint_group" "https" {
  listener_arn = aws_globalaccelerator_listener.https.id

  endpoint_group_region         = var.endpoint_group_region
  traffic_dial_percentage       = var.traffic_dial_percentage
  health_check_interval_seconds = var.health_check_interval_seconds
  health_check_path             = var.health_check_path
  health_check_protocol         = var.health_check_protocol
  health_check_port             = var.health_check_port
  threshold_count               = var.healthy_threshold_count

  endpoint_configuration {
    endpoint_id = var.alb_arn
    weight      = var.endpoint_weight
  }

  # Port overrides for HTTPS
  dynamic "port_override" {
    for_each = var.port_overrides_https
    content {
      listener_port = port_override.value.listener_port
      endpoint_port = port_override.value.endpoint_port
    }
  }
}
