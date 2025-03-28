provider "aws" {
  region = var.aws_region
}

# Create a random string for resource naming
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Create a random password for the database if not provided
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  count            = var.db_password == "" ? 1 : 0
}

locals {
  name_prefix = "${var.project_name}-${random_string.suffix.result}"
  db_password = var.db_password == "" ? random_password.db_password[0].result : var.db_password
  
  # Common tags for all resources
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Store database credentials in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${local.name_prefix}-db-credentials"
  description = "Database credentials for LiteLLM"
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id     = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = local.db_password
  })
}

# Networking module
module "networking" {
  source = "./modules/networking"

  name           = local.name_prefix
  vpc_cidr       = var.vpc_cidr
  azs            = var.availability_zones
  container_port = var.container_port
  tags           = local.tags
}

# Database module
module "database" {
  source = "./modules/database"

  name                = local.name_prefix
  db_name             = var.db_name
  db_username         = var.db_username
  db_password         = local.db_password
  db_subnet_group_name = module.networking.database_subnet_group_name
  security_group_id   = module.networking.database_security_group_id
  min_capacity        = var.min_capacity
  max_capacity        = var.db_max_capacity
  tags                = local.tags
}

# Read the LiteLLM config file
locals {
  litellm_config = fileexists(var.litellm_config_path) ? file(var.litellm_config_path) : ""
}

# Fargate module
module "fargate" {
  source = "./modules/fargate"

  name                      = local.name_prefix
  vpc_id                    = module.networking.vpc_id
  public_subnets            = module.networking.public_subnets
  private_subnets           = module.networking.private_subnets
  alb_security_group_id     = module.networking.alb_security_group_id
  ecs_tasks_security_group_id = module.networking.ecs_tasks_security_group_id
  container_image           = var.container_image
  container_port            = var.container_port
  cpu                       = var.cpu
  memory                    = var.memory
  desired_count             = var.desired_count
  max_capacity              = var.max_capacity
  db_host                   = module.database.endpoint
  db_port                   = module.database.port
  db_name                   = var.db_name
  db_username               = var.db_username
  db_secret_arn             = aws_secretsmanager_secret.db_credentials.arn
  aws_region                = var.aws_region
  config_parameter_name     = "/${local.name_prefix}/litellm/config"
  config_content            = local.litellm_config
  tags                      = local.tags
}
