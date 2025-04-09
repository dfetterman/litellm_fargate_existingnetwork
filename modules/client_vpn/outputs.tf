output "client_vpn_endpoint_id" {
  description = "ID of the Client VPN endpoint"
  value       = aws_ec2_client_vpn_endpoint.this.id
}

output "client_vpn_endpoint_dns_name" {
  description = "DNS name of the Client VPN endpoint"
  value       = aws_ec2_client_vpn_endpoint.this.dns_name
}

output "client_vpn_security_group_id" {
  description = "ID of the security group associated with the Client VPN endpoint"
  value       = aws_security_group.client_vpn.id
}

output "client_vpn_endpoint_arn" {
  description = "ARN of the Client VPN endpoint"
  value       = aws_ec2_client_vpn_endpoint.this.arn
}

output "client_vpn_self_service_portal_url" {
  description = "URL of the Client VPN self-service portal"
  value       = "https://${aws_ec2_client_vpn_endpoint.this.self_service_portal_url}"
}
