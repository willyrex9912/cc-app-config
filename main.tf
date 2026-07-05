# =============================================================================
# TERRAFORM CONFIGURATION
# =============================================================================
# Defines required providers (azurerm for Azure, kubernetes for K8s)
# and minimum Terraform version (>= 1.1.0)
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
  required_version = ">= 1.1.0"
}

# =============================================================================
# PROVIDERS
# =============================================================================
# Azure Resource Manager provider - manages Azure infrastructure (AKS, RG)
provider "azurerm" {
  features {}
}

# Kubernetes provider - deploys workloads to the AKS cluster
# Uses kube_config from the AKS cluster resource for authentication
provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.cluster.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.cluster.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.cluster.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.cluster.kube_config[0].cluster_ca_certificate)
}

# =============================================================================
# AZURE RESOURCES
# =============================================================================
# Resource group: logical container for all Azure resources
# Location: East US 2
resource "azurerm_resource_group" "rg" {
  name     = "rg-cc-app-prod"
  location = "eastus2"
}

# AKS cluster: managed Kubernetes cluster to run cc-app workloads
# - 2 nodes with Standard_D2s_v7 VMs
# - System-assigned managed identity for Azure AD integration
# - Free tier SKU
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

# =============================================================================
# KUBERNETES RESOURCES
# =============================================================================
# Deployment: runs 3 replicas of cc-app container
# - Image: jessieljuarez99/cc-app:latest
# - Container port: 4000
# - Uses label selector to match pods
resource "kubernetes_deployment" "cc_app" {
  metadata {
    name = "cc-app"
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "cc-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "cc-app"
        }
      }

      spec {
        container {
          name  = "cc-app"
          image = "jessieljuarez99/cc-app:latest"

          port {
            container_port = 4000
          }
        }
      }
    }
  }
}

# Service: LoadBalancer to expose cc-app externally
# - Frontend port 80 -> container port 4000
# - Type: LoadBalancer (gets external IP via Azure Load Balancer)
resource "kubernetes_service" "cc_app" {
  metadata {
    name = "cc-app"
  }

  spec {
    selector = {
      app = "cc-app"
    }

    port {
      port        = 80
      target_port = 4000
    }

    type = "LoadBalancer"
  }
}

# =============================================================================
# OUTPUTS
# =============================================================================
# External IP: public IP to access the cc-app in a browser
output "cc_app_external_ip" {
  value = kubernetes_service.cc_app.status[0].load_balancer[0].ingress[0].ip
}
