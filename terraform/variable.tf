variable "environment" {
  description = "Deployment environment: dev or prod"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be 'dev' or 'prod'."
  }
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "db_admin" {
  description = "SQL Server admin username"
  type        = string
}

variable "db_password" {
  description = "SQL Server admin password"
  type        = string
  sensitive   = true
}

variable "aad_admin_object_id" {
  description = "Azure AD object ID for SQL AAD admin"
  type        = string
  sensitive   = true
}