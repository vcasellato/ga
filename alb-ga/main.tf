# Data sources
data "aws_region" "current" {}

data "aws_vpc" "main" {
  id = var.vpc_id
}

data "aws_subnets" "public" {
  count = var.public_subnet_ids == null ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  tags = var.public_subnet_tags
}

# Get VPC Endpoint Network Interface details
data "aws_network_interface" "vpce" {
  count = length(var.vpc_endpoint_network_interface_ids)
  id    = var.vpc_endpoint_network_interface_ids[count.index]
}

# Security Group for ALB
resource "aws_security_group" "alb" {
  name_prefix = "${var.name}-alb-"
  vpc_id      = var.vpc_id
  description = "Security group for Global Accelerator ALB"

  # Allow HTTP from Global Accelerator
  ingress {
    description = "HTTP from Global Accelerator"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Permitir Global Accelerator de qualquer lugar
  }

  # Allow HTTPS from Global Accelerator
  ingress {
    description = "HTTPS from Global Accelerator"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Permitir Global Accelerator de qualquer lugar
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
    Name = "${var.name}-alb-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = var.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids != null ? var.public_subnet_ids : data.aws_subnets.public[0].ids

  enable_deletion_protection = var.enable_deletion_protection

  # Access logs
  dynamic "access_logs" {
    for_each = var.enable_access_logs ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = var.access_logs_prefix
      enabled = true
    }
  }

  tags = var.tags
}

# Target Group for VPC Endpoint IPs
resource "aws_lb_target_group" "vpce" {
  name     = "${var.name}-vpce-tg"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = var.vpc_id

  target_type = "ip"

  # Health check configuration - AJUSTADO para VPC Endpoint
  health_check {
    enabled             = true
    healthy_threshold   = var.health_check_healthy_threshold
    interval            = var.health_check_interval
    matcher             = "403" # CRÍTICO: API Gateway responde 403 para health checks
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = "HTTPS"
    timeout             = var.health_check_timeout
    unhealthy_threshold = var.health_check_unhealthy_threshold
  }

  tags = merge(var.tags, {
    Name = "${var.name}-vpce-tg"
  })
}

# Register VPC Endpoint Network Interface IPs as targets
resource "aws_lb_target_group_attachment" "vpce_ips" {
  count = length(var.vpc_endpoint_network_interface_ids)

  target_group_arn = aws_lb_target_group.vpce.arn
  target_id        = data.aws_network_interface.vpce[count.index].private_ip
  port             = 443
}

# HTTP Listener (redirect to HTTPS)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = var.tags
}

# HTTPS Listener (only if certificate is provided)
resource "aws_lb_listener" "https" {
  count = var.certificate_arn != null ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vpce.arn
  }

  tags = var.tags
}

# CloudWatch Log Group for ALB access logs (if using CloudWatch instead of S3)
resource "aws_cloudwatch_log_group" "alb_access_logs" {
  count             = var.enable_cloudwatch_logs ? 1 : 0
  name              = "/aws/applicationloadbalancer/${var.name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}
