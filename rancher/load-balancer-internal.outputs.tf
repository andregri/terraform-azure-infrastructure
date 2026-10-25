output "load_balancer_internal_ip_addr" {
    value = azurerm_lb.kube-vip.private_ip_address
}