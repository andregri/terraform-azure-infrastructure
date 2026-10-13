# Network Security Group for Rancher
resource "azurerm_network_security_group" "rancher" {
  name                = "rancher-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow HTTPS access to Rancher
  security_rule {
    name                       = "allow-https"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # Allow HTTP access (Rancher redirects to HTTPS)
  security_rule {
    name                       = "allow-http"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # Allow Azure Load Balancer health probes
  security_rule {
    name                       = "allow-azure-lb-probes"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }
}

# Associate the NSG with the existing Rancher subnet
resource "azurerm_subnet_network_security_group_association" "rancher" {
  subnet_id                 = module.rancher-cluster.subnet_id
  network_security_group_id = azurerm_network_security_group.rancher.id
}