param location string
param resourcePrefix string
  
resource appServicePlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: '${resourcePrefix}-asp'
  location: location
  sku: {
    name: 'S1'
    tier: 'Standard'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

output id string = appServicePlan.id
