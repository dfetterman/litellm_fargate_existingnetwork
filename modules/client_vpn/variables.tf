variable "name" {
  description = "Base name for resources"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "client_cidr_block" {
  description = "CIDR block for VPN client IP assignments"
  type        = string
  default     = "10.0.0.0/22"
}

variable "server_certificate_arn" {
  description = "ARN of the server certificate from ACM"
  type        = string
}

variable "client_certificate_arn" {
  description = "ARN of the client certificate from ACM"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}
