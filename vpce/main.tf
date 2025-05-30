# Data source to get current region
data "aws_region" "current" {}

# Data source to get VPC details
data "aws_vpc" "main" {
  id = var.vpc_id
}

# Data source to get internal ALB details
data "aws_lb" "internal_alb" {
  name = var.internal_alb_name # ou use arn se disponível: arn = var.internal_alb_arn
}

# Security Group for VPC Endpoint
resource "aws_security_group" "vpc_endpoint" {
  name_prefix = "${var.name}-vpce-"
  vpc_id      = var.vpc_id
  description = "Security group for API Gateway VPC Endpoint"

  # Allow HTTPS inbound from specified security groups or CIDR blocks
  dynamic "ingress" {
    for_each = length(var.allowed_security_groups) > 0 ? [1] : []
    content {
      description     = "HTTPS from allowed security groups"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      security_groups = var.allowed_security_groups
    }
  }

  dynamic "ingress" {
    for_each = length(var.allowed_cidrs) > 0 ? [1] : []
    content {
      description = "HTTPS from allowed CIDR blocks"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidrs
    }
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-vpce-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# VPC Endpoint for API Gateway Execute API
resource "aws_vpc_endpoint" "api_gateway" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.execute-api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = var.private_dns_enabled

  # Policy to allow access to API Gateway
  policy = var.endpoint_policy != null ? var.endpoint_policy : jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "execute-api:Invoke"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.name}-vpce"
  })
}

# VPC Link para conectar API Gateway ao ALB interno
resource "aws_api_gateway_vpc_link" "internal_alb" {
  name        = "${var.name}-internal-alb-link"
  description = "VPC Link to connect API Gateway to internal ALB"
  target_arns = [data.aws_lb.internal_alb.arn]

  tags = merge(var.tags, {
    Name = "${var.name}-internal-alb-vpc-link"
  })
}

# REST API
resource "aws_api_gateway_rest_api" "main" {
  name        = var.name
  description = var.description

  endpoint_configuration {
    types            = ["PRIVATE"]
    vpc_endpoint_ids = [aws_vpc_endpoint.api_gateway.id]
  }

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "execute-api:Invoke"
        Resource  = "arn:aws:execute-api:${data.aws_region.current.name}:*:*"
        Condition = {
          StringEquals = {
            "aws:sourceVpce" = aws_vpc_endpoint.api_gateway.id
          }
        }
      }
    ]
  })

  tags = var.tags
}

# Proxy resource to handle all paths
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "{proxy+}"
}

# Integration para o ALB interno via VPC Link
resource "aws_api_gateway_integration" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method

  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"

  # URI do ALB interno - usando hostname interno
  uri = "https://open-banking-proxy-internal.ob.dev.payabl1.com/{proxy}"

  # Usar VPC Link para conectividade
  connection_type = "VPC_LINK"
  connection_id   = aws_api_gateway_vpc_link.internal_alb.id

  # Pass through headers
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }

  # Timeout settings
  timeout_milliseconds = 29000

  depends_on = [aws_api_gateway_vpc_link.internal_alb]
}

# Method para proxy
resource "aws_api_gateway_method" "proxy" {
  rest_api_id      = aws_api_gateway_rest_api.main.id
  resource_id      = aws_api_gateway_resource.proxy.id
  http_method      = "ANY"
  authorization    = "NONE"
  api_key_required = true

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

# Method response
resource "aws_api_gateway_method_response" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# Integration response
resource "aws_api_gateway_integration_response" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = aws_api_gateway_method_response.proxy.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT,DELETE'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.proxy]
}

# API Key
resource "aws_api_gateway_api_key" "main" {
  name        = "${var.name}-api-key"
  description = "API Key for ${var.name}"
  enabled     = true

  tags = var.tags
}

# Usage Plan
resource "aws_api_gateway_usage_plan" "main" {
  name        = "${var.name}-usage-plan"
  description = "Usage plan for ${var.name}"

  api_stages {
    api_id = aws_api_gateway_rest_api.main.id
    stage  = aws_api_gateway_deployment.main.stage_name
  }

  quota_settings {
    limit  = var.quota_limit
    period = "DAY"
  }

  throttle_settings {
    rate_limit  = var.throttle_rate_limit
    burst_limit = var.throttle_burst_limit
  }

  tags = var.tags
}

# Usage Plan Key
resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = aws_api_gateway_api_key.main.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.main.id
}

# Deployment
resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = var.stage_name

  # Force redeploy when integration changes
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.proxy.id,
      aws_api_gateway_method.proxy.id,
      aws_api_gateway_integration.proxy.id,
      aws_api_gateway_vpc_link.internal_alb.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.proxy,
    aws_api_gateway_integration.proxy,
    aws_api_gateway_vpc_link.internal_alb
  ]

  tags = var.tags
}
