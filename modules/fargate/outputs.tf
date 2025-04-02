output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
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

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.main.arn
}

output "load_balancer_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.main.arn
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "ecr_image_uri" {
  description = "URI of the Docker image in ECR"
  value       = module.ecr.image_uri
}

output "ecr_image_tag" {
  description = "Tag of the Docker image in ECR"
  value       = module.ecr.image_tag
}
