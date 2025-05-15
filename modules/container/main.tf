# AWS Account - Get current account ID for ECR repository
data "aws_caller_identity" "current" {}

# Container Registry - ECR repository with vulnerability scanning
resource "aws_ecr_repository" "repository" {
  name = var.repository_name

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags
}

# Use a pre-built image instead of building one
locals {
  # Use a pre-built LiteLLM image from GitHub Container Registry
  use_prebuilt_image = var.use_prebuilt_image
  prebuilt_image_uri = "ghcr.io/berriai/litellm:litellm_stable_release_branch-v1.65.0-stable"
  
  # Always use latest tag for ECR images
  ecr_image_uri = local.use_prebuilt_image ? local.prebuilt_image_uri : "${aws_ecr_repository.repository.repository_url}:latest"
}

# Deployment - Build and push Docker image using local-exec script
resource "null_resource" "docker_build_and_push" {
  count = local.use_prebuilt_image ? 0 : 1
  
  provisioner "local-exec" {
    working_dir = "${path.module}/image"
    interpreter = ["/bin/bash", "-c"]
    command     = "../build/build_and_push.sh"
    environment = {
      AWS_ACCOUNT_ID     = data.aws_caller_identity.current.account_id
      AWS_REGION         = var.aws_region
      REPOSITORY_NAME    = var.repository_name
      ECR_REPOSITORY_URL = aws_ecr_repository.repository.repository_url
      ECR_IMAGE         = "${aws_ecr_repository.repository.repository_url}:latest"
    }
  }

  triggers = {
    # Trigger on file changes but don't use hash in tag
    content_hash = substr(sha256(join("", [
      filesha256("${path.module}/image/Dockerfile"),
      filesha256("${path.module}/image/litellm_config_load_balance.yaml"),
      filesha256("${path.module}/image/entrypoint.sh")
    ])), 0, 8)
  }

  depends_on = [aws_ecr_repository.repository]
}
