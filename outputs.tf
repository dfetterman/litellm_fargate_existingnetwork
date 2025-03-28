output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = module.fargate.load_balancer_dns
}

output "litellm_endpoint" {
  description = "Endpoint URL for the LiteLLM proxy"
  value       = "http://${module.fargate.load_balancer_dns}"
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

output "public_subnets" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnets
}

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
