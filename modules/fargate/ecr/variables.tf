variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "litellm-proxy"
}

variable "build_args" {
  description = "Build arguments for Docker build"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
