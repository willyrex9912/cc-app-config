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

provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "rg" {
  name = "rg-aks-demo-prod"
}

data "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-cluster-prod"
  resource_group_name = data.azurerm_resource_group.rg.name
}

provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.aks.kube_config[0].host
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
}

resource "kubernetes_deployment" "cc_app" {
  metadata {
    name = "cc-app"
    labels = {
      app = "cc-app"
    }
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

          resources {
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "cc_app" {
  metadata {
    name = "cc-app"
  }

  spec {
    type = "LoadBalancer"

    selector = {
      app = "cc-app"
    }

    port {
      port        = 80
      target_port = 4000
    }
  }
}

output "cc_app_external_ip" {
  value = kubernetes_service.cc_app.status[0].load_balancer[0].ingress[0].ip
}
