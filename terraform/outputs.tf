output "app_url" {
  description = "Public URL of the deployed web app"
  value       = "https://${azurerm_linux_web_app.app.default_hostname}"
}

output "app_name" {
  description = "App Service name — used by the deploy workflow"
  value       = azurerm_linux_web_app.app.name
}

output "sql_server_fqdn" {
  description = "SQL Server hostname"
  value       = azurerm_mssql_server.sql.fully_qualified_domain_name
  sensitive   = true
}