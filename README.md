# cc-app-config

Terraform configuration to deploy the **cc-app** container to an existing AKS cluster.

## Resources

| Resource | Description |
|----------|-------------|
| `kubernetes_deployment.cc_app` | 3 replicas of `jessieljuarez99/cc-app:latest` (port 4000) |
| `kubernetes_service.cc_app` | LoadBalancer exposing port 80 → 4000 |

## Prerequisites

- AKS cluster `aks-cluster-prod` in resource group `rg-aks-demo-prod` (managed in `../aks-terraform/`)
- Terraform >= 1.1.0

## Usage

```bash
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
