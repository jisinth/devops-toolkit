# resource_groups examples

## Summary

```bash
python3 resource_groups.py
```

```
Name       Location  ResourceCount
---------  --------  -------------
prod-rg    eastus    24
dev-rg     westus2   9
```

## With a per-type breakdown

```bash
python3 resource_groups.py --detailed
```

```
Resource type breakdown:
Name     Location  ResourceType                        Count
-------  --------  ----------------------------------  -----
prod-rg  eastus    Microsoft.Compute/virtualMachines    3
prod-rg  eastus    Microsoft.Network/networkInterfaces  3
prod-rg  eastus    Microsoft.Storage/storageAccounts    2
```
