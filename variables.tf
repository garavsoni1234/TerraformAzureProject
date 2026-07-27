# variables.tf
variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "name_prefix" {
  description = "Short prefix used to name resources consistently"
  type        = string
  default     = "myapp"
}