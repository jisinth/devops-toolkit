# aks_report examples

## Whole subscription

```bash
python3 aks_report.py
```

```
Name        ResourceGroup  KubernetesVersion  ProvisioningState  NodePools                    Location
----------  -------------  -----------------  -----------------  ---------------------------  --------
prod-aks    prod-rg        1.29.4             Succeeded          system:Standard_D4s_v3 x3     eastus
```

## Scoped to one resource group

```bash
python3 aks_report.py --resource-group prod-rg
```

## Write a JSON report

```bash
python3 aks_report.py --output aks-clusters.json
```
