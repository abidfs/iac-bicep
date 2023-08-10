param location string = resourceGroup().location
param resourcePrefix string = uniqueString(resourceGroup().id)
param tenantId string = subscription().tenantId

module vnet 'modules/vnet.bicep' = {
  name: 'module-vnet'
  params: {
    location: location
    resourcePrefix: resourcePrefix
  }
}

module managedIdentities 'modules/managed-identity.bicep' = {
  name: 'module-managed-identities'
  params: {
    location: location
    resourcePrefix: resourcePrefix
  }
}

module keyVault 'modules/key-vault.bicep' = {
  name: 'module-keyvault'
  params: {
    location: location
    resourcePrefix: resourcePrefix
    tenantId: tenantId
    principalId: managedIdentities.outputs.principalId
    privateEndpointsSubnetId: vnet.outputs.kvPrivateEndpointsSubnetId
    privateDnsZoneId: privateDnsZoneKeyvault.outputs.dnsZoneId
    secretsObject: {
      secrets: [
        { name: 'dbuser', value: resourcePrefix }
        { name: 'dbpassword', value: guid('${resourcePrefix}-password') } // use random string generator
      ]
    }
  }
}

resource keyVaultRef 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVault.outputs.name
}

module mysqlDatabaseServer 'modules/mysql-db.bicep' = {
  name: 'module-mysql-database'
  params: {
    location: location
    resourcePrefix: resourcePrefix
    databaseUser: keyVaultRef.getSecret('dbuser')
    databasePassword: keyVaultRef.getSecret('dbpassword')
    privateEndpointsSubnetId: vnet.outputs.dbPrivateEndpointsSubnetId
    dnsZoneId: privateDnsZone.outputs.dnsZoneId
  }
}

module appServicesPlan 'modules/app-service-plan.bicep' = {
  name: 'module-app-service-plan'
  params: {
    location: location
    resourcePrefix: resourcePrefix
  }
}

module appServicesWebApp 'modules/webapp.bicep' = {
  name: 'module-app-services-web-app-cms'
  params: {
    location: location
    resourcePrefix: resourcePrefix
    appServicePlanId: appServicesPlan.outputs.id
    appContainerImage: 'abidfs1/strapi-cms:3872a7ad2f5d02de2e49b1eb3e766e26bf76540b'
    // databaseUser: keyVaultRef.getSecret('dbuser') 
    // databasePassword: keyVaultRef.getSecret('dbpassword')
    appSettings: {
      nameValuePairs: [
        { name: 'ADMIN_JWT_SECRET', value: 'ECXOkBK440ZKX5z4cYGong==' } // load from keyvault
        { name: 'API_TOKEN_SALT', value: 'pdAYYFNV8jx4yIxQwHK7vA==' } // load from keyvault
        { name: 'APP_KEYS', value: 'z2uWyEmTKH/5I5f0wDXgTg==' } // load from keyvault
        { name: 'DATABASE_CLIENT', value: 'mysql2' }
        { name: 'VAULT_NAME', value: keyVault.outputs.name }
        // { name: 'DATABASE_HOST', value: '${mysqlDatabaseServer.outputs.databaseServerName}.${privateDnsZone.outputs.dnsZoneFqdn}' }
        { name: 'DATABASE_HOST', value: mysqlDatabaseServer.outputs.databaseHostName }
        { name: 'DATABASE_NAME', value: mysqlDatabaseServer.outputs.databaseName }
        { name: 'DATABASE_PORT', value: '3306' }
        { name: 'DATABASE_SSL', value: 'true' }
        { name: 'DOCKER_REGISTRY_SERVER_URL', value: 'https://index.docker.io/v1' }
        { name: 'JWT_SECRET', value: 'YwK0aaSPuHeEv7sl5gceGA==' } // load from keyvault
        { name: 'MANAGED_IDENTITY_CLIENT_ID', value: managedIdentities.outputs.clientId }
        { name: 'NODE_ENV', value: 'development' }
        { name: 'PORT', value: '1337' }
        { name: 'TRANSFER_TOKEN_SALT', value: '/E7Jii/NIXggKWrTyEqLSg==' } // load from keyvault
        { name: 'WEBSITE_HTTPLOGGING_RETENTION_DAYS', value: '1' }
        { name: 'WEBSITE_PORT', value: '1337' }
        { name: 'WEBSITES_PORT', value: '1337' }
        { name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE', value: 'false' }
      ]
    }
    managedIdentityId: managedIdentities.outputs.id
    vnetIntegrationSubnetId: vnet.outputs.vnetIntegrationSubnetId
  }
}

module privateDnsZone 'modules/private-dns.bicep' = {
  name: 'private-dns-zone-mysql-server'
  params: {
    dnsZoneName: '${resourcePrefix}.private.mysql.database.azure.com'
    virtualNetworkId: vnet.outputs.virtualNetworkId
    virtualNetworkName: vnet.name
  }
}

module privateDnsZoneKeyvault 'modules/private-dns.bicep' = {
  name: 'private-dns-zone-keyvault'
  params: {
    dnsZoneName: 'privatelink.vaultcore.azure.net'
    virtualNetworkId: vnet.outputs.virtualNetworkId
    virtualNetworkName: vnet.name
  }
}
