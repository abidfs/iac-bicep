param location string
param resourcePrefix string
param appServicePlanId string
param managedIdentityId string
param appContainerImage string
param vnetIntegrationSubnetId string
param frontDoorId string
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
      detailedErrorLoggingEnabled: true
      httpLoggingEnabled: true
      requestTracingEnabled: true
      ftpsState: 'Disabled'
      http20Enabled: true
      linuxFxVersion: 'DOCKER|${appContainerImage}'
      minTlsVersion: '1.2'
      ipSecurityRestrictions: [
        {
          tag: 'ServiceTag'
          ipAddress: 'AzureFrontDoor.Backend'
          action: 'Allow'
          priority: 100
          headers: {
            'x-azure-fdid': [
              frontDoorId
            ]
          }
          name: 'Allow traffic from Front Door'
        }
      ]
      vnetRouteAllEnabled: true
    }
    virtualNetworkSubnetId: vnetIntegrationSubnetId
  }
}

output appUrl string = appServiceWebApp.properties.defaultHostName
