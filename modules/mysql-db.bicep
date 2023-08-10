param location string
param resourcePrefix string
param databaseName string = '${resourcePrefix}-database'
@secure()
param databaseUser string
@secure()
param databasePassword string
param privateEndpointsSubnetId string
param dnsZoneId string

// For complete configuration visit
// https://learn.microsoft.com/en-us/azure/templates/microsoft.dbformysql/flexibleservers?pivots=deployment-language-bicep
// https://github.com/Azure/azure-quickstart-templates/tree/master/quickstarts/microsoft.dbformysql/flexible-mysql-with-vnet
// https://learn.microsoft.com/en-us/azure/mysql/flexible-server/quickstart-create-bicep
resource mySqlDatabaseServer 'Microsoft.DBforMySQL/flexibleServers@2022-09-30-preview' = {
  name: '${resourcePrefix}-mysql-server'
  location: location
  sku: {
    name: 'Standard_B1s'
    tier: 'Burstable'
  }
  properties: {
    administratorLogin: databaseUser
    administratorLoginPassword: databasePassword
    createMode: 'Default'
    version: '8.0.21'
    network: {
      delegatedSubnetResourceId: privateEndpointsSubnetId
      privateDnsZoneResourceId: dnsZoneId
      publicNetworkAccess: 'Disabled'
    }
  }

  resource mySqlDatabase 'databases@2022-01-01' = {
    name: databaseName
    properties: {
      charset: 'utf8'
      collation: 'utf8_general_ci'
    }
  }

  // resource firewallRuleAllowAzureIPs 'firewallRules@2022-01-01' = {
  //   name: 'AllowAzureIPs'
  //   properties: {
  //     startIpAddress: '0.0.0.0'
  //     endIpAddress: '255.255.255.255'
  //   }
  // }
}

output databaseServerName string = mySqlDatabaseServer.name
output databaseName string = databaseName
output databaseHostName string = mySqlDatabaseServer.properties.fullyQualifiedDomainName
