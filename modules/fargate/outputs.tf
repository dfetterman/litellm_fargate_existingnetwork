output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = var.alb_dns_name
}

output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.ecs.cluster_id
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "service_id" {
  description = "ID of the ECS service"
  value       = aws_ecs_service.litellm.id
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.litellm.name
}

output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = aws_ecs_task_definition.litellm.arn
}

# Removed invalid output referencing var.alb_target_group_arn

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = null # This is now provided by the container module in the root
}

output "ecr_image_uri" {
  description = "URI of the Docker image in ECR"
  value       = var.container_image_uri
}

output "ecr_image_tag" {
  description = "Tag of the Docker image in ECR"
  value       = split(":", var.container_image_uri)[1]
}

# Outputs related to NLB and VPC endpoint service removed as they are no longer needed with AWS Verified Access
