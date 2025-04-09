variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "db_name" {
  description = "Name of the database"
  type        = string
}

variable "db_username" {
  description = "Username for the database"
  type        = string
}

variable "db_password" {
  description = "Password for the database"
  type        = string
  sensitive   = true
}

variable "db_subnet_group_name" {
  description = "Name of the database subnet group"
  type        = string
}

variable "security_group_id" {
  description = "ID of the security group for the database"
  type        = string
}

variable "min_capacity" {
  description = "Minimum capacity for Aurora Serverless v2 in ACUs"
  type        = number
  default     = 0.5 # Minimum value for Aurora Serverless v2
}

variable "max_capacity" {
  description = "Maximum capacity for Aurora Serverless v2 in ACUs"
  type        = number
  default     = 4.0 # Adjust based on expected workload
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection for the database"
  type        = bool
  default     = false
}

# Backup variables removed - backups disabled

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "engine" {
  description = "Database engine type"
  type        = string
  default     = "aurora-postgresql"
}

variable "engine_mode" {
  description = "Database engine mode"
  type        = string
  default     = "provisioned"
}

variable "engine_version" {
  description = "PostgreSQL engine version for Aurora"
  type        = string
}
