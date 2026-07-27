# outputs.tf

output "web_app_default_hostname" {
  description = "Public hostname of the App Service"
  value       = azurerm_linux_web_app.this.default_hostname
}

output "web_app_principal_id" {
  description = "Object ID of the App Service's system-assigned managed identity"
  value       = azurerm_linux_web_app.this.identity[0].principal_id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.this.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.this.vault_uri
}
