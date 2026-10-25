output "app_gateway_public_ip" {
    value = azurerm_public_ip.appgw.ip_address
}