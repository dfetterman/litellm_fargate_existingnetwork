variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "litellm-proxy"
}

variable "scan_on_push" {
  description = "Enable image scanning on push"
  type        = bool
  default     = true
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

variable "use_prebuilt_image" {
  description = "Whether to use a pre-built image instead of building one"
  type        = bool
  default     = false
}
