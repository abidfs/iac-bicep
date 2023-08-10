```sh
# Create resource group
az group create --name uksc --location uksouth

# Deploy resources using main.bicep file
az deployment group create --resource-group uksc --template-file main.bicep

# Delete resource group at the end
az group delete --name uksc
```
