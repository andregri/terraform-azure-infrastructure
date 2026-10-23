resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-appgw"
  location            = var.location
  resource_group_name = var.resource_group_name

  address_space = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "appgw" {
  name                 = "snet-appgw"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name

  address_prefixes = ["10.0.10.0/24"]
}

resource "azurerm_public_ip" "appgw" {
  name                = "pip-appgw"
  location            = var.location
  resource_group_name = var.resource_group_name

  allocation_method = "Static"
  sku               = "Standard"
}

locals {
  frontend_ip_configuration_name  = "appgw-frontend-ip"
  frontend_port_name              = "appgw-frontend-http"
  frontend_port_name_https        = "appgw-frontend-https"
  backend_address_pool_name       = "appgw-backend-pool"
  backend_http_settings_name      = "appgw-backend-http"
  backend_https_settings_name     = "appgw-backend-https"
  listener_name                   = "appgw-listener-http"
  listener_name_https             = "appgw-listener-https"
  request_routing_rule_name       = "appgw-routing-rule-http"
  request_routing_rule_name_https = "appgw-routing-rule-https"
}

resource "azurerm_application_gateway" "appgw" {
  name                = "appgw-example"
  location            = var.location
  resource_group_name = var.resource_group_name

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "gateway-ip"
    subnet_id = azurerm_subnet.appgw.id
  }

  ssl_certificate {
    name     = "appgw-cert"
    data     = data.local_file.appgw_pfx.content_base64
    password = var.pfx_password
  }

  trusted_root_certificate {
    name = "root-ca"
    data = base64encode(tls_self_signed_cert.root.cert_pem)
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_port {
    name = local.frontend_port_name_https
    port = 443
  }

  backend_address_pool {
    name = local.backend_address_pool_name

    ip_addresses = [azurerm_lb.kube-vip.private_ip_address]
  }

  backend_http_settings {
    name                  = local.backend_http_settings_name
    cookie_based_affinity = "Disabled"

    protocol = "Http"
    port     = 80

    request_timeout = 30
  }

  backend_http_settings {
    name                  = local.backend_https_settings_name
    cookie_based_affinity = "Disabled"

    protocol = "Https"
    port     = 443

    trusted_root_certificate_names = [
      "root-ca"
    ]

    request_timeout = 30
  }

  http_listener {
    name = local.listener_name

    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name

    protocol = "Http"
  }

  http_listener {
    name = local.listener_name_https

    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name_https

    protocol             = "Https"
    ssl_certificate_name = "appgw-cert"
  }

  request_routing_rule {
    name = local.request_routing_rule_name

    rule_type = "Basic"
    priority  = 100

    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.backend_http_settings_name
  }

  request_routing_rule {
    name = local.request_routing_rule_name_https

    rule_type = "Basic"
    priority  = 120

    http_listener_name         = local.listener_name_https
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.backend_https_settings_name
  }
}
