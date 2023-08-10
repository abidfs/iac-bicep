param location string
param resourcePrefix string
param appServicePlanId string
param managedIdentityId string
param appContainerImage string
param vnetIntegrationSubnetId string
@secure()
param appSettings object

resource appServiceWebApp 'Microsoft.Web/sites@2021-02-01' = {
  name: '${resourcePrefix}-webapp'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    httpsOnly: true
    serverFarmId: appServicePlanId
    siteConfig: {
      alwaysOn: true
      appSettings: appSettings.nameValuePairs
      ftpsState: 'Disabled'
      http20Enabled: true
      linuxFxVersion: 'DOCKER|${appContainerImage}'
      minTlsVersion: '1.2'
      vnetRouteAllEnabled: true
    }
    virtualNetworkSubnetId: vnetIntegrationSubnetId
  }
}

output appUrl string = appServiceWebApp.properties.defaultHostName
output outboundIpAddresses array = concat(split(appServiceWebApp.properties.outboundIpAddresses, ','), split(appServiceWebApp.properties.possibleOutboundIpAddresses, ','))
