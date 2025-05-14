provider "aws" {
  region = var.aws_region
}

# Create a random string for resource naming
# Naming - 8 char random suffix for unique resource names
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Generate a random master key for LiteLLM
# Security - 32 char master key for LiteLLM proxy authentication
resource "random_password" "litellm_master_key" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Generate a random salt key for LiteLLM
resource "random_password" "litellm_salt_key" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Generate a random string to use as part of the password if not provided
resource "random_string" "db_password_suffix" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Naming - Combine project name with random suffix for resources
locals {
  name_prefix = "${var.project_name}-${random_string.suffix.result}"

  # Common tags for all resources
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
  
  # Use the provided password or generate a random one
  db_password = var.db_password != "" ? var.db_password : random_string.db_password_suffix.result
  
  # Format the master key with "sk" prefix
# Compatibility - Add 'sk-' prefix to match OpenAI API key format
  formatted_master_key = "sk-${random_password.litellm_master_key.result}"

  # Format the salt key with "sk" prefix
  formatted_salt_key = "sk-${random_password.litellm_salt_key.result}"
  
  # Generate database connection string
  db_connection_string = (
    module.database.endpoint != "" && module.database.port != 0 
    ? "postgresql://${var.db_username}:${local.db_password}@${module.database.endpoint}:${module.database.port}/${var.db_name}" 
    : ""
  )
}

# Networking module
# Networking - Private VPC with internal ALB and security groups
module "networking" {
  source = "./modules/networking"

  name                    = local.name_prefix
  vpc_cidr                = var.vpc_cidr
  azs                     = var.availability_zones
  container_port          = var.container_port
  on_premises_cidr_blocks = var.on_premises_cidr_blocks
  aws_region              = var.aws_region
  log_bucket_id           = module.logging.bucket_id
  environment             = var.environment
  tags                    = local.tags
  
  # VPC configuration
  create_vpc                      = var.create_vpc
  existing_vpc_id                 = var.existing_vpc_id
  existing_private_subnet_ids     = var.existing_private_subnet_ids
  existing_public_subnet_ids      = var.existing_public_subnet_ids
  existing_database_subnet_ids    = var.existing_database_subnet_ids
  existing_database_subnet_group_name = var.existing_database_subnet_group_name
}

# Database module - uses the generated password
module "database" {
  source = "./modules/database"

  name                 = local.name_prefix
  db_name              = var.db_name
  db_username          = var.db_username
  db_password          = local.db_password
  db_subnet_group_name = module.networking.database_subnet_group_name
  security_group_id    = module.networking.database_security_group_id
  min_capacity         = var.db_min_capacity
  max_capacity         = var.db_max_capacity
  engine               = var.db_engine
  engine_mode          = var.db_engine_mode
  engine_version       = var.db_engine_version
  deletion_protection  = var.db_deletion_protection
  tags                 = local.tags
}

# Logging module for S3 bucket logging
module "logging" {
  source = "./modules/logging"
  
  name = local.name_prefix
  tags = local.tags
}

# IAM module - simplified without secrets manager permissions
module "iam" {
  source = "./modules/iam"

  name = local.name_prefix
  tags = local.tags
}

# Container module
module "container" {
  source = "./modules/container"

  aws_region      = var.aws_region
  repository_name = local.name_prefix
  tags            = local.tags
}

# Fargate module
module "fargate" {
  source = "./modules/fargate"

  name                        = local.name_prefix
  vpc_id                      = module.networking.vpc_id
  private_subnets             = module.networking.private_subnets
  alb_security_group_id       = module.networking.alb_security_group_id
  ecs_tasks_security_group_id = module.networking.ecs_tasks_security_group_id
  azs                         = var.availability_zones
  vpc_cidr                    = var.vpc_cidr
  alb_target_group_arn        = module.networking.alb_target_group_arn
  alb_dns_name                = module.networking.alb_dns_name
  alb_arn                     = module.networking.alb_arn
  dockerfile_path             = "modules/fargate/container"
  container_port              = var.container_port
  cpu                         = var.cpu
  memory                      = var.memory
  desired_count               = var.desired_count
  max_capacity                = var.fargate_max_capacity
  database_url                = local.db_connection_string
  litellm_master_key          = local.formatted_master_key
  litellm_salt_key            = local.formatted_salt_key
  aws_region                  = var.aws_region
  log_bucket_id               = module.logging.bucket_id
  log_retention_days          = var.log_retention_days
  container_health_check_start_period = var.container_health_check_start_period
  container_health_check_path = var.container_health_check_path
  autoscaling_cpu_target      = var.autoscaling_cpu_target
  autoscaling_memory_target   = var.autoscaling_memory_target
  tags                        = local.tags
  
  # New parameters for the moved modules
  task_execution_role_arn     = module.iam.task_execution_role_arn
  task_role_arn               = module.iam.task_role_arn
  container_image_uri         = module.container.image_uri
}

# Verified Access module removed - using Client VPN instead

# Client VPN module - conditionally created
module "client_vpn" {
  source = "./modules/client_vpn"
  count  = var.enable_client_vpn ? 1 : 0

  name                   = local.name_prefix
  vpc_id                 = module.networking.vpc_id
  private_subnets        = module.networking.private_subnets
  client_cidr_block      = var.client_vpn_cidr
  server_certificate_arn = var.vpn_certificate_arn
  client_certificate_arn = var.vpn_certificate_arn
  vpc_cidr               = var.vpc_cidr
  tags                   = local.tags
}

# Output the generated secrets for reference
output "db_password" {
  description = "Database password (sensitive)"
  value       = local.db_password
  sensitive   = true
}

output "litellm_master_key" {
  description = "LiteLLM master key with sk prefix (sensitive)"
  value       = local.formatted_master_key
  sensitive   = true
}

output "litellm_salt_key" {
  description = "LiteLLM salt key with sk prefix (sensitive)"
  value       = local.formatted_salt_key
  sensitive   = true
}
