resource "azurerm_public_ip" "rancher" {
  name                = "rancher-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  domain_name_label   = "rancher3451342"
  allocation_method   = "Static"
}

resource "azurerm_lb" "rancher" {
  name                = "rancher-lb"
  location            = var.location
  resource_group_name = var.resource_group_name

  frontend_ip_configuration {
    name                 = "rancher-frontend-ip-conf"
    public_ip_address_id = azurerm_public_ip.rancher.id
  }
}

resource "azurerm_lb_backend_address_pool" "rancher" {
  loadbalancer_id = azurerm_lb.rancher.id
  name            = "rancher-ap"
}

resource "azurerm_lb_probe" "rancher-http" {
  loadbalancer_id = azurerm_lb.rancher.id
  name            = "rancher-http"
  protocol        = "Tcp"
  port            = 80
}

resource "azurerm_lb_probe" "rancher-https" {
  loadbalancer_id = azurerm_lb.rancher.id
  name            = "rancher-https"
  protocol        = "Tcp"
  port            = 443
}

resource "azurerm_lb_rule" "rancher-http" {
  loadbalancer_id                = azurerm_lb.rancher.id
  name                           = "rancher-http-lb-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "rancher-frontend-ip-conf"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.rancher.id]
  probe_id                       = azurerm_lb_probe.rancher-http.id
}

resource "azurerm_lb_rule" "rancher-https" {
  loadbalancer_id                = azurerm_lb.rancher.id
  name                           = "rancher-https-lb-rule"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "rancher-frontend-ip-conf"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.rancher.id]
  probe_id                       = azurerm_lb_probe.rancher-https.id
}

resource "azurerm_network_interface_backend_address_pool_association" "rancher" {
  for_each                = { for i, id in module.rancher-cluster.network_interface_ids : i => id }
  network_interface_id    = each.value
  ip_configuration_name   = "testconfiguration-${each.key}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.rancher.id
}
