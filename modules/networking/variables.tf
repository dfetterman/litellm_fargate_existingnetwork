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
