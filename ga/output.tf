output "accelerator_id" {
  description = "ID of the Global Accelerator"
  value       = aws_globalaccelerator_accelerator.main.id
}

output "accelerator_arn" {
  description = "ARN of the Global Accelerator"
  value       = aws_globalaccelerator_accelerator.main.arn
}

output "accelerator_dns_name" {
  description = "DNS name of the Global Accelerator"
  value       = aws_globalaccelerator_accelerator.main.dns_name
}

output "accelerator_hosted_zone_id" {
  description = "Hosted zone ID of the Global Accelerator"
  value       = aws_globalaccelerator_accelerator.main.hosted_zone_id
}

output "static_ip_addresses" {
  description = "Static IP addresses of the Global Accelerator"
  value       = aws_globalaccelerator_accelerator.main.ip_sets[0].ip_addresses
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = aws_globalaccelerator_listener.http.id
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener"
  value       = aws_globalaccelerator_listener.https.id
}

output "http_endpoint_group_arn" {
  description = "ARN of the HTTP endpoint group"
  value       = aws_globalaccelerator_endpoint_group.http.arn
}

output "https_endpoint_group_arn" {
  description = "ARN of the HTTPS endpoint group"
  value       = aws_globalaccelerator_endpoint_group.https.arn
}
