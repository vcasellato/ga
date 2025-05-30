# Data source to get current region
data "aws_region" "current" {}

# Data source to get VPC details
data "aws_vpc" "main" {
  id = var.vpc_id
}

# Data source para usar o VPC Endpoint existente
data "aws_vpc_endpoint" "existing_api_gateway" {
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${data.aws_region.current.name}.execute-api"
}

# Security Group for VPC Endpoint (mantido para compatibilidade)
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

# REST API
resource "aws_api_gateway_rest_api" "main" {
  name        = var.name
  description = var.description

  endpoint_configuration {
    types            = ["PRIVATE"]
    vpc_endpoint_ids = [data.aws_vpc_endpoint.existing_api_gateway.id]
  }

  # Política permissiva para permitir ALB → VPC Endpoint → API Gateway
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "execute-api:Invoke"
        Resource  = "*"
      }
    ]
  })

  tags = var.tags
}

# Root resource method (ANY on /)
resource "aws_api_gateway_method" "root" {
  rest_api_id      = aws_api_gateway_rest_api.main.id
  resource_id      = aws_api_gateway_rest_api.main.root_resource_id
  http_method      = "ANY"
  authorization    = "NONE"
  api_key_required = true
}

# Root integration (ANY on /)
resource "aws_api_gateway_integration" "root" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.root.http_method

  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "https://open-banking-proxy-internal.ob.dev.payabl1.com/"

  timeout_milliseconds = 29000
}

# Root method response
resource "aws_api_gateway_method_response" "root" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.root.http_method
  status_code = "200"
}

# Root integration response
resource "aws_api_gateway_integration_response" "root" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.root.http_method
  status_code = aws_api_gateway_method_response.root.status_code

  depends_on = [aws_api_gateway_integration.root]
}

# Proxy resource to handle all paths
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "{proxy+}"
}

# Method para proxy - APENAS ANY
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

# Integration para o ALB interno via Private DNS (ou VPC Link se fallback)
resource "aws_api_gateway_integration" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method

  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"

  # URI - usa Private DNS por padrão, NLB se fallback habilitado
  uri = var.create_nlb_fallback ? "https://${aws_lb.internal_nlb_fallback[0].dns_name}/{proxy}" : "https://${var.internal_alb_dns_name}/{proxy}"

  # Connection type - usa VPC Link se NLB, senão default (sem INTERNET)
  connection_type = var.create_nlb_fallback ? "VPC_LINK" : null
  connection_id   = var.create_nlb_fallback ? aws_api_gateway_vpc_link.internal_nlb[0].id : null

  # Request parameters para mapear o path
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }

  # Timeout settings
  timeout_milliseconds = 29000

  depends_on = [
    aws_api_gateway_vpc_link.internal_nlb
  ]
}

# Method response - APENAS para ANY
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

# Integration response - APENAS para ANY
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

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.main.id}/${var.stage_name}"
  retention_in_days = 14

  tags = var.tags
}

# IAM Role for API Gateway CloudWatch Logging
resource "aws_iam_role" "api_gateway_cloudwatch" {
  name_prefix = "${substr(var.name, 0, 20)}-apigw-cw-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for API Gateway CloudWatch Logging
resource "aws_iam_role_policy" "api_gateway_cloudwatch" {
  name_prefix = "${substr(var.name, 0, 20)}-apigw-cw-"
  role        = aws_iam_role.api_gateway_cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# API Gateway Account Configuration for CloudWatch
resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch.arn
}

# Deployment with basic stage
resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = var.stage_name

  # Force redeploy when integration changes
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.proxy.id,
      aws_api_gateway_method.proxy.id,
      aws_api_gateway_integration.proxy.id,
      timestamp(), # Force rebuild
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.root,
    aws_api_gateway_integration.root,
    aws_api_gateway_method.proxy,
    aws_api_gateway_integration.proxy,
    aws_api_gateway_method_response.root,
    aws_api_gateway_integration_response.root,
    aws_api_gateway_method_response.proxy,
    aws_api_gateway_integration_response.proxy,
    aws_api_gateway_account.main
  ]
}

# Method Settings for detailed logging (using deployment stage)
resource "aws_api_gateway_method_settings" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_deployment.main.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled        = true
    logging_level          = "INFO" # ERROR, INFO, or OFF
    data_trace_enabled     = true
    throttling_rate_limit  = var.throttle_rate_limit
    throttling_burst_limit = var.throttle_burst_limit
  }
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

  depends_on = [aws_api_gateway_deployment.main]
}

# Data source para pegar informações do ALB interno
data "aws_lb" "internal_alb" {
  arn = var.internal_alb_arn
}

# Data source para usar a Private Hosted Zone existente
data "aws_route53_zone" "private" {
  name         = var.private_dns_domain
  private_zone = true
  vpc_id       = var.vpc_id
}

# Note: DNS record open-banking-proxy-internal.ob.dev.payabl1.com already exists
# in the private hosted zone and points to the internal ALB

# Security Group para NLB (caso precise de fallback)
resource "aws_security_group" "nlb_fallback" {
  count       = var.create_nlb_fallback ? 1 : 0
  name_prefix = "${var.name}-nlb-fallback-"
  vpc_id      = var.vpc_id
  description = "Security group for NLB fallback"

  # Allow HTTPS traffic
  ingress {
    description = "HTTPS from API Gateway"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  # Allow HTTP traffic
  ingress {
    description = "HTTP from API Gateway"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  # All outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-nlb-fallback-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# NLB como fallback (se Private DNS não funcionar)
resource "aws_lb" "internal_nlb_fallback" {
  count              = var.create_nlb_fallback ? 1 : 0
  name               = "${substr(var.name, 0, 18)}-nlb-fb" # Máximo 32 chars
  internal           = true
  load_balancer_type = "network"
  subnets            = var.subnet_ids # Usa as mesmas subnets do VPC Endpoint
  security_groups    = [aws_security_group.nlb_fallback[0].id]

  enable_deletion_protection = false

  tags = merge(var.tags, {
    Name = "${var.name}-nlb-fallback"
  })
}

# Target Group para NLB apontando para ALB
resource "aws_lb_target_group" "alb_targets" {
  count       = var.create_nlb_fallback ? 1 : 0
  name        = "${substr(var.name, 0, 20)}-alb-tg" # Máximo 32 chars
  port        = 443
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "alb"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    protocol            = "TCP"
    port                = "443"
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 10
  }

  tags = merge(var.tags, {
    Name = "${var.name}-alb-targets"
  })
}

# Anexar ALB como target do NLB
resource "aws_lb_target_group_attachment" "alb" {
  count            = var.create_nlb_fallback ? 1 : 0
  target_group_arn = aws_lb_target_group.alb_targets[0].arn
  target_id        = data.aws_lb.internal_alb.arn
}

# Listener HTTPS do NLB
resource "aws_lb_listener" "nlb_https" {
  count             = var.create_nlb_fallback ? 1 : 0
  load_balancer_arn = aws_lb.internal_nlb_fallback[0].arn
  port              = "443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_targets[0].arn
  }

  tags = var.tags
}

# VPC Link para o NLB (se usar NLB)
resource "aws_api_gateway_vpc_link" "internal_nlb" {
  count       = var.create_nlb_fallback ? 1 : 0
  name        = "${var.name}-nlb-vpc-link"
  description = "VPC Link to internal NLB"
  target_arns = [aws_lb.internal_nlb_fallback[0].arn]

  tags = merge(var.tags, {
    Name = "${var.name}-nlb-vpc-link"
  })
}

# Usage Plan Key
resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = aws_api_gateway_api_key.main.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.main.id
}
