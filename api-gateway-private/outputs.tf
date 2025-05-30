# Outputs
output "vpc_endpoint_id" {
  description = "ID of the existing VPC Endpoint"
  value       = data.aws_vpc_endpoint.existing_api_gateway.id
}

output "vpc_endpoint_arn" {
  description = "ARN of the existing VPC Endpoint"
  value       = data.aws_vpc_endpoint.existing_api_gateway.arn
}

output "vpc_endpoint_hosted_zone_id" {
  description = "Hosted zone ID of the existing VPC Endpoint"
  value       = length(data.aws_vpc_endpoint.existing_api_gateway.dns_entry) > 0 ? data.aws_vpc_endpoint.existing_api_gateway.dns_entry[0].hosted_zone_id : null
}

output "security_group_id" {
  description = "Security group ID for the VPC Endpoint (created by this module)"
  value       = aws_security_group.vpc_endpoint.id
}

output "network_interface_ids" {
  description = "Network interface IDs of the existing VPC Endpoint"
  value       = data.aws_vpc_endpoint.existing_api_gateway.network_interface_ids
}

output "private_ips" {
  description = "Use AWS CLI to get private IPs of the existing VPC Endpoint"
  value       = "Run: aws ec2 describe-network-interfaces --network-interface-ids ${join(" ", data.aws_vpc_endpoint.existing_api_gateway.network_interface_ids)} --query 'NetworkInterfaces[].PrivateIpAddress' --output json"
}

output "get_private_ips_command" {
  description = "AWS CLI command to get private IPs of the existing VPC Endpoint"
  value       = "aws ec2 describe-network-interfaces --network-interface-ids ${join(" ", data.aws_vpc_endpoint.existing_api_gateway.network_interface_ids)} --query 'NetworkInterfaces[].PrivateIpAddress' --output json"
}

output "vpc_endpoint_dns_names" {
  description = "DNS names of the existing VPC Endpoint"
  value       = data.aws_vpc_endpoint.existing_api_gateway.dns_entry[*].dns_name
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

# VPC Link outputs removed since we're not using VPC Link anymore

output "api_gateway_invoke_url_vpc" {
  description = "VPC Endpoint invoke URL"
  value       = "https://${aws_api_gateway_rest_api.main.id}-vpce-${data.aws_vpc_endpoint.existing_api_gateway.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${var.stage_name}"
}

output "test_command_vpc_endpoint" {
  description = "Test command for VPC endpoint"
  value       = "curl -X POST 'https://${aws_api_gateway_rest_api.main.id}-vpce-${data.aws_vpc_endpoint.existing_api_gateway.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${var.stage_name}/proxy' -H 'x-api-key: ${aws_api_gateway_api_key.main.value}' -H 'x-cip-destination: https://bank-proxy.dev.payabl1.com:9441' -H 'x-cip-reference-id: 900' -H 'x-cip-amount: 100' -H 'x-cip-currency: EUR' -v"
  sensitive   = true
}

output "existing_vpc_endpoint_info" {
  description = "Information about the existing VPC Endpoint being used"
  value = {
    id                 = data.aws_vpc_endpoint.existing_api_gateway.id
    state              = data.aws_vpc_endpoint.existing_api_gateway.state
    subnet_ids         = data.aws_vpc_endpoint.existing_api_gateway.subnet_ids
    security_group_ids = data.aws_vpc_endpoint.existing_api_gateway.security_group_ids
  }
}
