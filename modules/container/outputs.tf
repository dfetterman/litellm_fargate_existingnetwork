output "repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.repository.repository_url
}

output "repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.repository.name
}

output "image_uri" {
  description = "URI of the container image"
  value       = local.ecr_image_uri
}
