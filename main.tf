provider "aws" {
  region = var.aws_region
}

# Create a random string for resource naming
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

locals {
  name_prefix = "${var.project_name}-${random_string.suffix.result}"

  # Common tags for all resources
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Networking module
module "networking" {
  source = "./modules/networking"

  name                    = local.name_prefix
  vpc_cidr                = var.vpc_cidr
  azs                     = var.availability_zones
  container_port          = var.container_port
  on_premises_cidr_blocks = var.on_premises_cidr_blocks
  aws_region              = var.aws_region
  tags                    = local.tags
}

# Create a random password for the database if not provided
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  count            = var.db_password == "" ? 1 : 0
}

locals {
  db_password = var.db_password == "" ? random_password.db_password[0].result : var.db_password
}

# Database module
module "database" {
  source = "./modules/database"

  name                 = local.name_prefix
  db_name              = var.db_name
  db_username          = var.db_username
  db_password          = local.db_password
  db_subnet_group_name = module.networking.database_subnet_group_name
  security_group_id    = module.networking.database_security_group_id
  min_capacity         = var.min_capacity
  max_capacity         = var.db_max_capacity
  tags                 = local.tags
}

# Secrets module
module "secrets" {
  source = "./modules/fargate/secrets"

  name        = local.name_prefix
  tags        = local.tags
  db_username = var.db_username
  db_password = local.db_password
  db_name     = var.db_name
  db_host     = module.database.endpoint
  db_port     = module.database.port
}

# Logging module for S3 bucket logging
module "logging" {
  source = "./modules/logging"
  
  name = local.name_prefix
  tags = local.tags
}

# Security module for WAF
module "security" {
  source = "./modules/security"
  
  name = local.name_prefix
  tags = local.tags
}

# Fargate module
module "fargate" {
  source = "./modules/fargate"

  name                        = local.name_prefix
  vpc_id                      = module.networking.vpc_id
  # public_subnets not needed since ALB is always internal
  private_subnets             = module.networking.private_subnets
  alb_security_group_id       = module.networking.alb_security_group_id
  ecs_tasks_security_group_id = module.networking.ecs_tasks_security_group_id
  dockerfile_path             = "modules/fargate/container"
  container_port              = var.container_port
  cpu                         = var.cpu
  memory                      = var.memory
  desired_count               = var.desired_count
  max_capacity                = var.max_capacity
  db_host                     = module.database.endpoint
  db_port                     = module.database.port
  db_name                     = var.db_name
  db_username                 = var.db_username
  litellm_secrets_arn         = module.secrets.litellm_secrets_arn
  aws_region                  = var.aws_region
  log_bucket_id               = module.logging.bucket_id
  web_acl_arn                 = module.security.web_acl_arn
  log_retention_days          = 90  # Set CloudWatch log retention to 90 days
  # ALB is always internal and in private subnets
  tags                        = local.tags
}
