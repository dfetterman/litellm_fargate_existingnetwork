output "repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.repository.repository_url
}

output "image_uri" {
  description = "URI of the Docker image in ECR"
  value       = local.ecr_image_uri
}

output "image_tag" {
  description = "Tag of the Docker image in ECR"
  value       = local.ecr_image_tag
}
