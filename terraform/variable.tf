#--------------------------
# General Variables
#--------------------------
variable "location" {
  description = "Azure region. Student account restricted to francecentral."
  type        = string
  default     = "francecentral"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be 'dev' or 'prod'."
  }
}

#--------------------------
# Resource Group
#--------------------------
variable "rg_name" {
  description = "Name of the Resource Group"
  type        = string
  default     = "rg-10alytics-dev"
}

#--------------------------
# App Service
#--------------------------
variable "app_service_sku" {
  description = "SKU for App Service Plan. B1 is within student quota."
  type        = string
  default     = "B1"
}

#--------------------------
# Database
#--------------------------
variable "db_admin" {
  description = "SQL Server administrator username"
  type        = string
}

variable "db_password" {
  description = "SQL Server administrator password"
  type        = string
  sensitive   = true
}

#--------------------------
# Azure Authentication
#--------------------------
variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "azure_tenant_id" {
  description = "Azure tenant ID"
  type        = string
}