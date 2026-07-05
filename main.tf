terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-cc-app-prod"
  location = "eastus2"
}

resource "azurerm_kubernetes_cluster" "cluster" {
  name                = "cc-app-cluster-prod"
  location            = "eastus2"
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "ccappprod"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_D2s_v7"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Production"
  }
}
