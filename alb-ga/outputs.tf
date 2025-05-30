output "alb_id" {
  description = "ID of the load balancer"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.main.arn
}

output "alb_arn_suffix" {
  description = "ARN suffix for use with CloudWatch Metrics"
  value       = aws_lb.main.arn_suffix
}

output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Canonical hosted zone ID of the load balancer"
  value       = aws_lb.main.zone_id
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.vpce.arn
}

output "target_group_arn_suffix" {
  description = "ARN suffix for use with CloudWatch Metrics"
  value       = aws_lb_target_group.vpce.arn_suffix
}

output "security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener (if certificate provided)"
  value       = var.certificate_arn != null ? aws_lb_listener.https[0].arn : null
}

output "vpc_endpoint_ips" {
  description = "Private IPs of VPC Endpoint network interfaces"
  value       = data.aws_network_interface.vpce[*].private_ip
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch Log Group name for ALB access logs"
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.alb_access_logs[0].name : null
}
