# keyvault.tf

data "azurerm_client_config" "current" {}

# Terraform runs from outside the VNet, so a fully public-disabled vault would 403 even the
# deployer's own data-plane calls (e.g. writing the secret below). Allow-listing the deployer's
# current public IP keeps the vault deny-by-default while still letting Terraform manage it.
data "http" "my_ip" {
  url = "https://api.ipify.org?format=text"
}

resource "azurerm_key_vault" "this" {
  name                = "kv-${var.name_prefix}-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  enable_rbac_authorization = true

  public_network_access_enabled = true
  purge_protection_enabled      = false
  soft_delete_retention_days    = 7

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = [chomp(data.http.my_ip.response_body)]
  }
}

resource "azurerm_private_endpoint" "vault" {
  name                = "${azurerm_key_vault.this.name}-pe"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "psc-keyvault"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.vault.id]
  }
}

# Terraform's own principal needs data-plane rights before it can write the secret below;
# RBAC on the vault grants nothing automatically, including to the deployer.
resource "azurerm_role_assignment" "deployer_secrets_officer" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "webapp_secrets_user" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_web_app.this.identity[0].principal_id
}

resource "azurerm_key_vault_secret" "storage_conn" {
  name         = "storage-connection-string"
  value        = azurerm_storage_account.this.primary_connection_string
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [azurerm_role_assignment.deployer_secrets_officer]
}
