resource "azurerm_lb" "kube-vip" {
  name                = "kube-vip-lb"
  location            = var.location
  resource_group_name = var.resource_group_name

  frontend_ip_configuration {
    name                          = "kube-vip-frontend-ip-conf"
    subnet_id                     = module.rancher-cluster.subnet_id
    private_ip_address_allocation = "Dynamic"
    private_ip_address_version    = "IPv4"
  }
}

resource "azurerm_lb_backend_address_pool" "kube-vip" {
  loadbalancer_id = azurerm_lb.kube-vip.id
  name            = "kube-vip-ap"
}

resource "azurerm_lb_probe" "rke2-registration" {
  loadbalancer_id = azurerm_lb.kube-vip.id
  name            = "rke2-registration-probe"
  protocol        = "Tcp"
  port            = 9345
}

resource "azurerm_lb_probe" "kube-apiserver" {
  loadbalancer_id = azurerm_lb.kube-vip.id
  name            = "kube-apiserver-probe"
  protocol        = "Tcp"
  port            = 6443
}

resource "azurerm_lb_rule" "rancher-registration" {
  loadbalancer_id                = azurerm_lb.kube-vip.id
  name                           = "registration-lb-rule"
  protocol                       = "Tcp"
  frontend_port                  = 9345
  backend_port                   = 9345
  frontend_ip_configuration_name = "kube-vip-frontend-ip-conf"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.kube-vip.id]
  probe_id                       = azurerm_lb_probe.rke2-registration.id
}

resource "azurerm_lb_rule" "kube-apiserver" {
  loadbalancer_id                = azurerm_lb.kube-vip.id
  name                           = "apiserver-lb-rule"
  protocol                       = "Tcp"
  frontend_port                  = 6443
  backend_port                   = 6443
  frontend_ip_configuration_name = "kube-vip-frontend-ip-conf"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.kube-vip.id]
  probe_id                       = azurerm_lb_probe.kube-apiserver.id
}

resource "azurerm_network_interface_backend_address_pool_association" "kube-vip" {
  for_each                = { for i, id in module.rancher-cluster.network_interface_ids : i => id }
  network_interface_id    = each.value
  ip_configuration_name   = "testconfiguration-${each.key}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.kube-vip.id
}
