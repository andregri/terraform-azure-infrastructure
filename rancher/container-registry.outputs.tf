output "acr_name" {
  value = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "acr_id" {
  value = azurerm_container_registry.acr.id
}

output "acr_login_str" {
  value = "az acr login --name ${azurerm_container_registry.acr.name} --expose-token"
}
