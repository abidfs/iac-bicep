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

module managedIdentityCms 'modules/managed-identity.bicep' = {
  name: 'module-managed-identities'
  params: {
    location: location
    resourcePrefix: resourcePrefix
  }
}

// // ADMIN_JWT_SECRET API_TOKEN_SALT APP_KEYS JWT_SECRET TRANSFER_TOKEN_SALT
// module randomStringGenerator 'modules/random-string-generator.bicep' = {
//   name: 'random-string-generator'
//   params: {
//     location: location
//   }
// }

module keyVault 'modules/key-vault.bicep' = {
  name: 'module-keyvault'
  params: {
    location: location
    resourcePrefix: resourcePrefix
    tenantId: tenantId
    principalId: managedIdentityCms.outputs.principalId
    privateEndpointsSubnetId: vnet.outputs.kvPrivateEndpointsSubnetId
    privateDnsZoneId: privateDnsZoneKeyvault.outputs.dnsZoneId
    secretsObject: {
      secrets: [
        { name: 'dbuser', value: resourcePrefix }
        { name: 'dbpassword', value: base64(guid('${resourcePrefix}-password')) } // use random string generator
        { name: 'appKeys', value: base64(guid('${resourcePrefix}-appKeys')) }
        { name: 'jwtSecret', value: base64(guid('${resourcePrefix}-jwtSecret')) }
        { name: 'adminJwtSecret', value: base64(guid('${resourcePrefix}-adminJwtSecret')) }
        { name: 'adminApiTokenSalt', value: base64(guid('${resourcePrefix}-adminApiTokenSalt')) }
        { name: 'adminTransferTokenSalt', value: base64(guid('${resourcePrefix}-adminTransferTokenSalt')) }
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
    dnsZoneId: privateDnsZoneDb.outputs.dnsZoneId
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
  dependsOn: [
    privateDnsZoneKeyvault
  ]
  params: {
    location: location
    resourcePrefix: resourcePrefix
    appServicePlanId: appServicesPlan.outputs.id
    appContainerImage: 'abidfs1/strapi-cms:d93c076b79ded7e027f37da7ff7ca3fb4ff3d435'
    appSettings: {
      nameValuePairs: [
        { name: 'DATABASE_CLIENT', value: 'mysql2' }
        { name: 'VAULT_NAME', value: keyVault.outputs.name }
        { name: 'DATABASE_HOST', value: mysqlDatabaseServer.outputs.databaseHostName }
        { name: 'DATABASE_NAME', value: mysqlDatabaseServer.outputs.databaseName }
        { name: 'DATABASE_PORT', value: '3306' }
        { name: 'DATABASE_SSL', value: 'true' }
        { name: 'DOCKER_REGISTRY_SERVER_URL', value: 'https://index.docker.io/v1' }
        { name: 'MANAGED_IDENTITY_CLIENT_ID', value: managedIdentityCms.outputs.clientId }
        { name: 'NODE_ENV', value: 'development' }
        { name: 'PORT', value: '1337' }
        { name: 'WEBSITE_HTTPLOGGING_RETENTION_DAYS', value: '1' }
        { name: 'WEBSITE_PORT', value: '1337' }
        { name: 'WEBSITES_PORT', value: '1337' }
        { name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE', value: 'false' }
      ]
    }
    managedIdentityId: managedIdentityCms.outputs.id
    vnetIntegrationSubnetId: vnet.outputs.vnetIntegrationSubnetId
  }
}

module privateDnsZoneDb 'modules/private-dns.bicep' = {
  name: 'private-dns-zone-mysql-server'
  params: {
    dnsZoneName: '${resourcePrefix}.mysql.database.azure.com'
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
