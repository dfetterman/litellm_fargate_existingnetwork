variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "db_username" {
  description = "Username for the database"
  type        = string
}

variable "db_password" {
  description = "Password for the database (if empty, a random password will be generated)"
  type        = string
  default     = ""
}

variable "db_name" {
  description = "Name of the database"
  type        = string
}

variable "db_host" {
  description = "Hostname of the database"
  type        = string
}

variable "db_port" {
  description = "Port of the database"
  type        = number
}
