variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnets" {
  description = "IDs of the public subnets"
  type        = list(string)
}

variable "private_subnets" {
  description = "IDs of the private subnets"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "ID of the security group for the ALB"
  type        = string
}

variable "ecs_tasks_security_group_id" {
  description = "ID of the security group for the ECS tasks"
  type        = string
}

variable "container_image" {
  description = "Docker image for the LiteLLM container"
  type        = string
}

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

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
}

variable "db_host" {
  description = "Hostname of the database"
  type        = string
}

variable "db_port" {
  description = "Port of the database"
  type        = number
}

variable "db_name" {
  description = "Name of the database"
  type        = string
}

variable "db_username" {
  description = "Username for the database"
  type        = string
}

variable "db_secret_arn" {
  description = "ARN of the database credentials secret in AWS Secrets Manager"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "config_parameter_name" {
  description = "Name of the SSM Parameter Store parameter containing the LiteLLM config in YAML format"
  type        = string
  default     = "/litellm/config"
}

variable "config_content" {
  description = "Content of the LiteLLM config in YAML format (will be stored in SSM Parameter Store)"
  type        = string
  default     = ""
}
