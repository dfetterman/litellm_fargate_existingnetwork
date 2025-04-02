variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "List of availability zones to use"
  type        = list(string)
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 4000
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "on_premises_cidr_blocks" {
  description = "List of CIDR blocks for your on-premises network"
  type        = list(string)
  default     = []
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}
