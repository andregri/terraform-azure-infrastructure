terraform {
  required_version = ">= 1.0.0"

  backend "azurerm" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {}
}

provider "tls" {}

provider "random" {}