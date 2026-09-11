terraform {
  required_version = ">= 1.0.0"

  backend "azurerm" {
    resource_group_name  = var.resource_group_name
    storage_account_name = "tfstatestorageacc4562"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.5.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {}
}
