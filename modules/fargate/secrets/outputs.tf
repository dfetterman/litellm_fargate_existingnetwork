output "litellm_secrets_arn" {
  description = "ARN of the consolidated LiteLLM secrets in AWS Secrets Manager"
  value       = aws_secretsmanager_secret.litellm_secrets.arn
}

output "litellm_secrets_name" {
  description = "Name of the consolidated LiteLLM secrets in AWS Secrets Manager"
  value       = aws_secretsmanager_secret.litellm_secrets.name
}

output "db_password" {
  description = "Database password (sensitive)"
  value       = local.db_password
  sensitive   = true
}
