variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "litellm"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "litellm"
}

variable "db_username" {
  description = "Username for the database"
  type        = string
  default     = "litellm"
}

variable "db_password" {
  description = "Password for the database (if empty, a random password will be generated)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "environment" {
  description = "Environment name (dev/stage/prod)"
  type        = string
  default     = "dev"
}

# Verified Access variables removed - using Client VPN instead

variable "vpn_certificate_arn" {
  description = "ARN of the ACM certificate for the Client VPN endpoint. You must create a server certificate in AWS Certificate Manager before deployment."
  type        = string
  default     = "arn:aws:acm:us-east-1:629763229779:certificate/77db9523-f871-44e2-a437-0f96380644b6"
}

variable "enable_client_vpn" {
  description = "Whether to enable the Client VPN endpoint"
  type        = bool
  default     = false
}

variable "client_vpn_cidr" {
  description = "CIDR block for VPN client IP assignments"
  type        = string
  default     = "172.16.0.0/22"
}

variable "db_min_capacity" {
  description = "Minimum capacity for Aurora Serverless v2 in ACUs"
  type        = number
  default     = 0.5 # Minimum value for Aurora Serverless v2
}

variable "db_max_capacity" {
  description = "Maximum capacity for Aurora Serverless v2 in ACUs"
  type        = number
  default     = 4.0 # Adjust based on expected workload
}

# Container image is now built and pushed to ECR by the ecr_container module

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 4000
}

variable "cpu" {
  description = "CPU units for the Fargate task"
  type        = number
  default     = 1024 # 1 vCPU
}

variable "memory" {
  description = "Memory for the Fargate task in MiB"
  type        = number
  default     = 2048 # 2 GB
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 1
}

variable "fargate_max_capacity" {
  description = "Maximum number of tasks for Fargate autoscaling"
  type        = number
  default     = 2
}

variable "on_premises_cidr_blocks" {
  description = "List of CIDR blocks for your on-premises network"
  type        = list(string)
  default     = []
}

# Removed unused variable: customer_gateway_ip_address

# IP addresses allowed for access control
variable "allowed_ip_addresses" {
  description = "List of IP addresses allowed to access the service (in CIDR notation, e.g., 203.0.113.0/24)"
  type        = list(string)
  default     = []
}

# ===== Database Configuration =====
variable "db_engine" {
  description = "Database engine type"
  type        = string
  default     = "aurora-postgresql"
}

variable "db_engine_mode" {
  description = "Database engine mode"
  type        = string
  default     = "provisioned"
}

variable "db_engine_version" {
  description = "PostgreSQL engine version for Aurora"
  type        = string
  default     = "15.4"
}

variable "db_deletion_protection" {
  description = "Whether to enable deletion protection for the database"
  type        = bool
  default     = false
}

# ===== Fargate and Container Configuration =====
variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 90
}

variable "container_health_check_start_period" {
  description = "Grace period for container health checks (seconds)"
  type        = number
  default     = 120
}

variable "container_health_check_path" {
  description = "Path for container health checks"
  type        = string
  default     = "/health/liveliness"
}

variable "autoscaling_cpu_target" {
  description = "Target CPU utilization percentage for autoscaling"
  type        = number
  default     = 70
}

variable "autoscaling_memory_target" {
  description = "Target memory utilization percentage for autoscaling"
  type        = number
  default     = 70
}

# ===== Existing VPC Configuration =====
variable "create_vpc" {
  description = "Whether to create a new VPC (true) or use an existing one (false)"
  type        = bool
  default     = false
}

variable "existing_vpc_id" {
  description = "ID of an existing VPC to use if create_vpc is false"
  type        = string
  default     = "vpc-0a86e94a1fe7ecadd"
}

variable "existing_private_subnet_ids" {
  description = "List of existing private subnet IDs to use if create_vpc is false"
  type        = list(string)
  default     = ["subnet-0955d2af5022254c6", "subnet-00972a36a6726e9e7"]
}

variable "existing_public_subnet_ids" {
  description = "List of existing public subnet IDs to use if create_vpc is false"
  type        = list(string)
  default     = ["subnet-05391ef2154bc4fbf", "subnet-06c762431c89c93a1"]
}

variable "existing_database_subnet_ids" {
  description = "List of existing database subnet IDs to use if create_vpc is false"
  type        = list(string)
  default     = []
}

variable "existing_database_subnet_group_name" {
  description = "Name of existing database subnet group to use if create_vpc is false"
  type        = string
  default     = ""
}
