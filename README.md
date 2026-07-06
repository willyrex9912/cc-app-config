# cc-app-config

Terraform configuration to deploy the **cc-app** container to AKS. This config creates the AKS cluster, resource group, and all Kubernetes resources from scratch.

## Resources

| Resource | Description |
|----------|-------------|
| `azurerm_resource_group.rg` | Resource group `rg-cc-app-prod` in `eastus2` |
| `azurerm_kubernetes_cluster.cluster` | AKS cluster `cc-app-cluster-prod` (2 nodes, `Standard_D2s_v7`, SystemAssigned identity) |
| `kubernetes_deployment.cc_app` | 3 replicas of `jessieljuarez99/cc-app:latest` (container port 4000) |
| `kubernetes_service.cc_app` | LoadBalancer exposing port 80 -> 4000 |

## Prerequisites

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/) logged in (`az login`)
- Terraform >= 1.1.0
- Provider `hashicorp/azurerm` **~> 3.0**
- Provider `hashicorp/kubernetes` **~> 2.0**

## Usage

```bash
az login
cd cc-app-config
terraform init
terraform plan
terraform apply
```

## Output

After apply, the external IP is available:

```bash
terraform output cc_app_external_ip
```

Access the app at `http://<EXTERNAL_IP>`.

## Cleanup

```bash
terraform destroy
```
