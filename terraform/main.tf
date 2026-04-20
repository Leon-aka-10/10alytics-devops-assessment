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
  subscription_id = "3088b175-92ef-4dd7-9020-ee7ae696fd1a"
  tenant_id       = "5fe78ac1-1afe-4009-aa04-a71efb4a5042"
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
# App Service Plan
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
    always_on = false
    application_stack {
      python_version = "3.11"
    }
    health_check_path = "/health"
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    "ENVIRONMENT"              = "dev"
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
# SQL Database
#--------------------------
resource "azurerm_mssql_database" "db" {
  name      = "appdb-dev"
  server_id = azurerm_mssql_server.sql.id
  sku_name  = "Basic"
}

#--------------------------
# Firewall: Azure services only
#--------------------------
resource "azurerm_mssql_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}