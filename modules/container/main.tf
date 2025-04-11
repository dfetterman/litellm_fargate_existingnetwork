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

# Build - Generate deterministic image tag from content hashes
locals {
  content_hash = substr(sha256(join("", [
    filesha256("${path.module}/image/Dockerfile"),
    filesha256("${path.module}/image/litellm_config.yaml"),
    filesha256("${path.module}/image/entrypoint.sh")
  ])), 0, 8)

  ecr_image_tag = local.content_hash
  ecr_image_uri = "${aws_ecr_repository.repository.repository_url}:${local.ecr_image_tag}"
}


# Deployment - Build and push Docker image using local-exec script
resource "null_resource" "docker_build_and_push" {
  provisioner "local-exec" {
    working_dir = "${path.module}/image"
    interpreter = ["/bin/bash", "-c"]
    command     = "../build/build_and_push.sh"
    environment = {
      AWS_ACCOUNT_ID     = data.aws_caller_identity.current.account_id
      AWS_REGION         = var.aws_region
      REPOSITORY_NAME    = var.repository_name
      ECR_REPOSITORY_URL = aws_ecr_repository.repository.repository_url
      ECR_IMAGE          = local.ecr_image_uri
      BUILD_ARGS         = join(" ", [for key, value in var.build_args : "--build-arg ${key}=${value}"])
    }
  }

  triggers = {
    content_hash = local.content_hash
  }

  depends_on = [aws_ecr_repository.repository]
}
