terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
  required_version = ">= 1.5.0"
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  tenant_id       = var.azure_tenant_id
}

resource "random_string" "rand" {
  length  = 6
  special = false
  upper   = false
}

#--------------------------
# Resource Group
#--------------------------
resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
}

#--------------------------
# App Service Plan (B1 - within student limits)
#--------------------------
resource "azurerm_service_plan" "app_plan" {
  name                = "asp-10alytics-dev"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = var.app_service_sku
}

#--------------------------
# Linux Web App
#--------------------------
resource "azurerm_linux_web_app" "app" {
  name                = "app-10alytics-dev-${random_string.rand.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.app_plan.id
  https_only          = true

  site_config {
    always_on = false  # Must be false on B1 SKU
    application_stack {
      python_version = "3.11"
    }
    health_check_path = "/health"
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    "ENVIRONMENT"              = var.environment
    "DB_CONNECTION_STRING"     = "Server=tcp:${azurerm_mssql_server.sql.fully_qualified_domain_name},1433;Database=appdb-dev;User ID=${var.db_admin};Password=${var.db_password};Encrypt=true;TrustServerCertificate=false;"
  }
}

#--------------------------
# SQL Server
#--------------------------
resource "azurerm_mssql_server" "sql" {
  name                         = "sql-10alytics-dev-${random_string.rand.result}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.db_admin
  administrator_login_password = var.db_password
}

#--------------------------
# SQL Database (Basic - cheapest tier)
#--------------------------
resource "azurerm_mssql_database" "db" {
  name      = "appdb-dev"
  server_id = azurerm_mssql_server.sql.id
  sku_name  = "Basic"
}

#--------------------------
# Firewall: allow Azure services only
#--------------------------
resource "azurerm_mssql_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}