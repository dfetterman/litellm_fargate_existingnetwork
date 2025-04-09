output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = module.fargate.load_balancer_dns
}

output "litellm_internal_endpoint" {
  description = "Internal endpoint URL for the LiteLLM proxy (internal ALB)"
  value       = "http://${module.fargate.load_balancer_dns}"
}

# Verified Access outputs removed - using Client VPN instead

# Client VPN outputs
output "client_vpn_endpoint_dns_name" {
  description = "DNS name of the Client VPN endpoint"
  value       = var.enable_client_vpn ? module.client_vpn[0].client_vpn_endpoint_dns_name : null
}

output "client_vpn_self_service_portal_url" {
  description = "URL of the Client VPN self-service portal"
  value       = var.enable_client_vpn ? module.client_vpn[0].client_vpn_self_service_portal_url : null
}

output "access_instructions" {
  description = "Instructions for accessing the service"
  value       = "This service is deployed with an internal ALB accessible via Client VPN. Connect to the VPN using the OpenVPN client and access the internal ALB endpoint."
}

output "database_endpoint" {
  description = "Endpoint of the Aurora database"
  value       = module.database.endpoint
}

output "database_port" {
  description = "Port of the Aurora database"
  value       = module.database.port
}

output "database_reader_endpoint" {
  description = "Reader endpoint of the Aurora database"
  value       = module.database.reader_endpoint
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "private_subnets" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnets
}

# Removed public_subnets output as we no longer have public subnets

output "database_subnets" {
  description = "IDs of the database subnets"
  value       = module.networking.database_subnets
}

output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.fargate.cluster_id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.fargate.cluster_name
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.fargate.ecr_repository_url
}

output "ecr_image_uri" {
  description = "URI of the Docker image in ECR"
  value       = module.fargate.ecr_image_uri
}

output "ecr_image_tag" {
  description = "Tag of the Docker image in ECR"
  value       = module.fargate.ecr_image_tag
}

# Cognito Authentication outputs removed - using internal ALB with security groups instead
