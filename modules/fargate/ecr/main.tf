# Get Account ID
data "aws_caller_identity" "current" {}

# ECR repository
resource "aws_ecr_repository" "repository" {
  name = var.repository_name

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags
}

# Generate Unique ECR Image Tag
locals {
  ecr_image_tag = substr(uuid(), 0, 8)
  ecr_image_uri = "${aws_ecr_repository.repository.repository_url}:${local.ecr_image_tag}"
}

# Build and push Docker image to ECR
resource "null_resource" "docker_build_and_push" {
  provisioner "local-exec" {
    working_dir = "${path.module}/../container"
    interpreter = ["/bin/bash", "-c"]
    command     = "./build_and_push.sh"
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
    dockerfile_hash  = filesha256("${path.module}/../container/Dockerfile")
    config_hash      = filesha256("${path.module}/../container/config/litellm_config.yaml")
    startup_hash     = filesha256("${path.module}/../container/startup.sh")
    image_tag        = local.ecr_image_tag
  }

  depends_on = [aws_ecr_repository.repository]
}
