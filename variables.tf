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
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "db_instance_type" {
  description = "Instance type for the database (only used for non-serverless instances)"
  type        = string
  default     = "db.t3.small"
}

variable "min_capacity" {
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

variable "max_capacity" {
  description = "Maximum number of tasks for autoscaling"
  type        = number
  default     = 2
}

variable "enable_s3_bucket" {
  description = "Whether to create an S3 bucket for logs and artifacts"
  type        = bool
  default     = false
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
  default     = null
}

variable "on_premises_cidr_blocks" {
  description = "List of CIDR blocks for your on-premises network"
  type        = list(string)
  default     = []
}

variable "customer_gateway_ip_address" {
  description = "IP address of your on-premises VPN device"
  type        = string
  default     = ""
}

# Authentication Variables removed - using internal ALB with security groups instead
