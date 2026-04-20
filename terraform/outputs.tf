output "app_url" {
  description = "Public hostname of the deployed web app"
  value       = azurerm_linux_web_app.app.default_hostname
}

output "app_name" {
  description = "App Service resource name (used in deploy step)"
  value       = azurerm_linux_web_app.app.name
}

output "sql_fqdn" {
  description = "SQL Server fully qualified domain name"
  value       = azurerm_mssql_server.sql.fully_qualified_domain_name
  sensitive   = true
}