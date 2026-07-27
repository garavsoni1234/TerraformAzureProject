# TerraformAzureProject

Terraform configuration that provisions a small, private Azure environment: an **App Service**, a **Storage Account**, and a **Key Vault**, networked together with **Private Endpoints** so the App Service reaches Storage and Key Vault without going over the public internet.

## What gets deployed

- **Resource group** — container for all resources below.
- **Networking** — a virtual network with two subnets: one delegated to App Service for VNet Integration, one dedicated to private endpoints. Includes private DNS zones (`privatelink.blob.core.windows.net`, `privatelink.vaultcore.azure.net`) linked to the VNet so private endpoint names resolve to private IPs.
- **Storage Account** — public network access disabled; reachable only through its private endpoint.
- **Key Vault** — RBAC-authorized, reachable through its private endpoint; holds the storage account's connection string as a secret.
- **App Service** — a Linux App Service Plan (Basic B1, the lowest tier that supports outbound VNet Integration) running a Linux Web App. VNet-integrated with a system-assigned managed identity, and configured with a Key Vault reference app setting so it reads the storage connection string securely at runtime instead of a hardcoded value.

The App Service's own public URL stays reachable from the internet (inbound private endpoints require a Premium App Service plan, out of scope here) — only its *outbound* calls to Storage and Key Vault are private.

## File layout

| File | Contents |
|---|---|
| `main.tf` | Resource group, shared random suffix for globally-unique names |
| `providers.tf` | Provider requirements and the remote state backend |
| `variables.tf` | Input variables (`resource_group_name`, `location`, `name_prefix`) |
| `networking.tf` | VNet, subnets, private DNS zones and VNet links |
| `storage.tf` | Storage account and its private endpoint |
| `keyvault.tf` | Key Vault, its private endpoint, RBAC role assignments, and the connection-string secret |
| `appservice.tf` | App Service Plan and Linux Web App |
| `outputs.tf` | App hostname, storage account name, Key Vault URI, web app identity |

## State

Terraform state is stored remotely in an Azure Storage Account (`azurerm` backend), not committed to this repo. State access uses Azure AD authentication (`use_azuread_auth = true`), so no storage account keys are needed locally.

## Usage

Requires the [Azure CLI](https://learn.microsoft.com/cli/azure/) logged in (`az login`) and Terraform >= 1.5.0.

Create a `terraform.tfvars` (gitignored) with at least:

```hcl
resource_group_name = "your-resource-group-name"
location             = "eastus"
```

Then:

```bash
terraform init
terraform plan -out=tfplan
terraform apply "tfplan"
```

## Verifying it's actually private

After applying, confirm the App Service resolves Storage/Key Vault to private IPs rather than public ones (e.g. via the App Service's SSH/Kudu console with `nslookup <storage-account>.blob.core.windows.net`), and check **Configuration → Application settings** in the portal to confirm the Key Vault-referenced setting shows as "Resolved".
