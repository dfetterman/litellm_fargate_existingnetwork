# Create a random password for the database if not provided
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  count            = var.db_password == "" ? 1 : 0
}

# Generate a random master key for LiteLLM
resource "random_password" "litellm_master_key" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Local variables
locals {
  db_password = var.db_password == "" ? random_password.db_password[0].result : var.db_password
}

# Store all secrets in a single AWS Secrets Manager secret
resource "aws_secretsmanager_secret" "litellm_secrets" {
  name                           = "${var.name}-litellm-secrets-new"  # Changed name to avoid conflict
  description                    = "Consolidated secrets for LiteLLM application"
  recovery_window_in_days        = 0  # Force immediate deletion without recovery window
  force_overwrite_replica_secret = true
  tags                           = var.tags
}

resource "aws_secretsmanager_secret_version" "litellm_secrets" {
  secret_id = aws_secretsmanager_secret.litellm_secrets.id
  secret_string = jsonencode({
    # Database credentials
    db_username          = var.db_username
    db_password          = local.db_password
    db_connection_string = "postgresql://${var.db_username}:${local.db_password}@${var.db_host}:${var.db_port}/${var.db_name}"
    
    # LiteLLM master key
    litellm_master_key   = random_password.litellm_master_key.result
  })
}
