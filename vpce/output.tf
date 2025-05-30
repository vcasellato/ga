# Outputs
output "vpc_endpoint_id" {
  description = "ID of the VPC Endpoint"
  value       = aws_vpc_endpoint.api_gateway.id
}

output "vpc_endpoint_arn" {
  description = "ARN of the VPC Endpoint"
  value       = aws_vpc_endpoint.api_gateway.arn
}

output "vpc_endpoint_hosted_zone_id" {
  description = "Hosted zone ID of the VPC Endpoint"
  value       = length(aws_vpc_endpoint.api_gateway.dns_entry) > 0 ? aws_vpc_endpoint.api_gateway.dns_entry[0].hosted_zone_id : null
}

output "security_group_id" {
  description = "Security group ID for the VPC Endpoint"
  value       = aws_security_group.vpc_endpoint.id
}

output "network_interface_ids" {
  description = "Network interface IDs of the VPC Endpoint"
  value       = aws_vpc_endpoint.api_gateway.network_interface_ids
}

output "private_ips" {
  description = "Use AWS CLI to get private IPs: aws ec2 describe-network-interfaces --network-interface-ids ENI_ID --query 'NetworkInterfaces[].PrivateIpAddress'"
  value       = "Run: aws ec2 describe-network-interfaces --network-interface-ids ${join(" ", aws_vpc_endpoint.api_gateway.network_interface_ids)} --query 'NetworkInterfaces[].PrivateIpAddress' --output json"
}

output "get_private_ips_command" {
  description = "AWS CLI command to get private IPs"
  value       = "aws ec2 describe-network-interfaces --network-interface-ids ${join(" ", aws_vpc_endpoint.api_gateway.network_interface_ids)} --query 'NetworkInterfaces[].PrivateIpAddress' --output json"
}

output "vpc_endpoint_dns_names" {
  description = "DNS names of the VPC Endpoint"
  value       = aws_vpc_endpoint.api_gateway.dns_entry[*].dns_name
}

output "api_gateway_id" {
  description = "ID of the API Gateway"
  value       = aws_api_gateway_rest_api.main.id
}

output "api_gateway_arn" {
  description = "ARN of the API Gateway"
  value       = aws_api_gateway_rest_api.main.arn
}

output "api_key_id" {
  description = "ID of the API Key"
  value       = aws_api_gateway_api_key.main.id
}

output "api_key_value" {
  description = "Value of the API Key"
  value       = aws_api_gateway_api_key.main.value
  sensitive   = true
}

output "vpc_link_id" {
  description = "ID of the VPC Link"
  value       = aws_api_gateway_vpc_link.internal_alb.id
}

output "vpc_link_status" {
  description = "Status of the VPC Link"
  value       = aws_api_gateway_vpc_link.internal_alb.status
}

output "api_gateway_invoke_url_vpc" {
  description = "VPC Endpoint invoke URL"
  value       = "https://${aws_api_gateway_rest_api.main.id}-vpce-${aws_vpc_endpoint.api_gateway.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${var.stage_name}"
}

output "test_command_vpc_endpoint" {
  description = "Test command for VPC endpoint"
  value = "curl -X POST 'https://${aws_api_gateway_rest_api.main.id}-vpce-${aws_vpc_endpoint.api_gateway.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${var.stage_name}/proxy' -H 'x-api-key: ${aws_api_gateway_api_key.main.value}' -H 'x-cip-destination: https://bank-proxy.dev.payabl1.com:9441' -H 'x-cip-reference-id: 900' -H 'x-cip-amount: 100' -H 'x-cip-currency: EUR' -v"
  sensitive = true
}
