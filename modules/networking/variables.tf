variable "log_bucket_id" {
  description = "ID of the S3 bucket for ALB access logs"
  type        = string
}

variable "cloudfront_privatelink_service_name" {
  description = "Name of the CloudFront PrivateLink service to connect to"
  type        = string
  default     = ""
}

variable "name" {
  description = "Base name for resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "container_port" {
  description = "Container port number"
  type        = number
}

variable "on_premises_cidr_blocks" {
  description = "List of on-premises CIDR blocks"
  type        = list(string)
}

variable "environment" {
  description = "Environment name (dev/stage/prod)"
  type        = string
  default     = "dev"
}

variable "create_vpc" {
  description = "Whether to create a new VPC (true) or use an existing one (false)"
  type        = bool
  default     = true
}

variable "existing_vpc_id" {
  description = "ID of an existing VPC to use if create_vpc is false"
  type        = string
  default     = ""
}

variable "existing_private_subnet_ids" {
  description = "List of existing private subnet IDs to use if create_vpc is false"
  type        = list(string)
  default     = []
}

variable "existing_public_subnet_ids" {
  description = "List of existing public subnet IDs to use if create_vpc is false"
  type        = list(string)
  default     = []
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

variable "existing_private_route_table_ids" {
  description = "List of existing private route table IDs to use for VPC endpoints"
  type        = list(string)
  default     = []
}
