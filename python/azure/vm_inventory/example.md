# vm_inventory examples

## Whole subscription

```bash
export AZURE_SUBSCRIPTION_ID=00000000-0000-0000-0000-000000000000
python3 vm_inventory.py
```

```
Name    ResourceGroup  Size             PowerState  Location    OsType
------  -------------  ---------------  ----------  ----------  -------
web-1   prod-rg        Standard_D2s_v3  running     eastus      Linux
db-1    prod-rg        Standard_D4s_v3  running     eastus      Linux
test-1  dev-rg         Standard_B2s     deallocated westus2     Windows
```

## Scoped to one resource group

```bash
python3 vm_inventory.py --resource-group prod-rg
```

## Write a CSV report

```bash
python3 vm_inventory.py --output vms.csv
```
