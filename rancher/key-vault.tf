resource "random_string" "kv_suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_key_vault" "kv" {
  name                = "keyvault${random_string.kv_suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group_name

  tenant_id = data.azurerm_client_config.current.tenant_id
  sku_name  = "standard"

  soft_delete_retention_days = 90
  purge_protection_enabled   = false

  rbac_authorization_enabled = true
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault_secret" "flux_git_token" {
  name         = "flux-git-token"
  value        = var.flux_git_token
  key_vault_id = azurerm_key_vault.kv.id

  content_type = "text/plain"
}

resource "azurerm_key_vault_secret" "registry_username" {
  name         = "registry-username"
  value        = azurerm_container_registry.acr.admin_username
  key_vault_id = azurerm_key_vault.kv.id

  content_type = "text/plain"
}

resource "azurerm_key_vault_secret" "registry_password" {
  name         = "registry-password"
  value        = azurerm_container_registry.acr.admin_password
  key_vault_id = azurerm_key_vault.kv.id

  content_type = "text/plain"
}