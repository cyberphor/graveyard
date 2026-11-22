variable "location" {
  type    = string
  default = "eastus"
}

variable "resource_group_name" {
  type    = string
  default = "cloud-security-task-01"
}

variable "db_name" {
  type    = string
  default = "vulnerable-db"
}

variable "admin_username" {
  type    = string
}

variable "admin_password" {
  type    = string
}