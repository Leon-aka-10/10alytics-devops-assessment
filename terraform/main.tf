terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.90" }
    random  = { source = "hashicorp/random", version = "~> 3.5" }
  }
  required_version = ">= 1.5.0"
}

provider "azurerm" {
  features {}
}

resource "random_string" "rand" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-10alytics-${var.environment}"
  location = var.location
}

# App Service Plan
resource "azurerm_service_plan" "app_plan" {
  name                = "asp-10alytics-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = var.environment == "prod" ? "P1v3" : "B1"
}

# Linux Web App
resource "azurerm_linux_web_app" "app" {
  name                = "app-10alytics-${var.environment}-${random_string.rand.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.app_plan.id
  https_only          = true

  site_config {
    always_on = true
    application_stack {
      python_version = "3.11"
    }
    health_check_path = "/health"
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    "ENVIRONMENT"              = var.environment
    # Connection string injected via Key Vault reference (production pattern)
    "DB_CONNECTION_STRING" = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.db_conn.id})"
  }

  identity {
    type = "SystemAssigned"
  }
}

# SQL Server
resource "azurerm_mssql_server" "sql" {
  name                         = "sql-10alytics-${var.environment}-${random_string.rand.result}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.db_admin
  administrator_login_password = var.db_password

  azuread_administrator {
    login_username = "aad-admin"
    object_id      = var.aad_admin_object_id
  }
}

# SQL Database
resource "azurerm_mssql_database" "db" {
  name      = "appdb-${var.environment}"
  server_id = azurerm_mssql_server.sql.id
  sku_name  = var.environment == "prod" ? "S1" : "Basic"

  lifecycle {
    prevent_destroy = true  # Protect prod data from accidental tf destroy
  }
}

# Firewall: allow only Azure services (no public internet access)
resource "azurerm_mssql_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Key Vault for secret injection
resource "azurerm_key_vault" "kv" {
  name                = "kv-10alytics-${var.environment}-${random_string.rand.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  purge_protection_enabled = var.environment == "prod"
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault_secret" "db_conn" {
  name         = "db-connection-string"
  value        = "Server=tcp:${azurerm_mssql_server.sql.fully_qualified_domain_name},1433;Database=${azurerm_mssql_database.db.name};User ID=${var.db_admin};Password=${var.db_password};Encrypt=true;"
  key_vault_id = azurerm_key_vault.kv.id
}

# Grant the App Service identity access to Key Vault
resource "azurerm_key_vault_access_policy" "app" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_web_app.app.identity[0].principal_id

  secret_permissions = ["Get"]
}