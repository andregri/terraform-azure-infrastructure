resource "random_string" "acr_suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_container_registry" "acr" {
  name                = "acr${random_string.acr_suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group_name

  sku           = "Basic"
  admin_enabled = true
}
