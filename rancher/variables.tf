variable "https_port" {
  type    = number
  default = 443
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "tenant_id" {
  type = string
}

variable "client_id" {
  type = string
}

variable "client_secret" {
  type = string
}

variable "resource_group_name" {
  type = string
}