variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "litellm_secrets_arn" {
  description = "ARN of the consolidated LiteLLM secrets in AWS Secrets Manager"
  type        = string
}

variable "master_key_secret_arn" {
  description = "ARN of the LiteLLM master key secret in AWS Secrets Manager"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
