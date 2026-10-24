resource "azurerm_virtual_network_peering" "appgw_to_rancher" {
  name                      = "appgw-to-rancher"
  resource_group_name = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.appgw.name
  remote_virtual_network_id = module.rancher-cluster.vnet_id

  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "rancher_to_appgw" {
  name                      = "rancher-to-appgw"
  resource_group_name = var.resource_group_name
  virtual_network_name      = module.rancher-cluster.vnet_name
  remote_virtual_network_id = azurerm_virtual_network.appgw.id

  allow_virtual_network_access = true
}
