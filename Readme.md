```sh
# Create resource group
az group create --name rg --location uksouth

# Deploy resources using main.bicep file
az deployment group create --resource-group rg --template-file main.bicep

# Delete resource group at the end
az group delete --name rg
```
