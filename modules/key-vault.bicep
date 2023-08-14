param location string
param resourcePrefix string
param privateEndpointsSubnetId string
param privateDnsZoneId string
param tenantId string
param principalId string
@description('Specifies all secrets {"name":"","value":""} wrapped in a secure object.')
@secure()
param secretsObject object

// https://learn.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults
// https://learn.microsoft.com/en-us/azure/key-vault/general/private-link-diagnostics
// https://github.com/MicrosoftDocs/azure-docs/issues/52649#issuecomment-648318286
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: '${resourcePrefix}-kv'
  location: location
  properties: {
    enabledForTemplateDeployment: true
    // enablePurgeProtection: true
    enableRbacAuthorization: true
    enableSoftDelete: false

    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: privateEndpointsSubnetId
        }
      ]
    }
    publicNetworkAccess: 'Disabled'
    softDeleteRetentionInDays: 7
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: tenantId
  }
}

resource keyVaultPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: '${resourcePrefix}-keyvault-private-endpoint'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${resourcePrefix}-keyvault-private-endpoint-con'
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
    subnet: {
      id: privateEndpointsSubnetId
    }
    customDnsConfigs: [
      {
        fqdn: '${keyVault.name}.vaultcore.azure.net'
      }
    ]
  }
}

resource keyVaultPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-04-01' = {
  name: '${resourcePrefix}-kv-private-dns-zone'
  parent: keyVaultPrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'dnsConfig'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

// @description('This is the built-in Key Vault Administrator role. See https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#key-vault-administrator')
resource roleAssignmentMi 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('${resourcePrefix}-role-assignment-mi')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '00482a5a-887f-4fb3-b363-3b7fe8e74483')
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

resource roleAssignmentSelf 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('${resourcePrefix}-role-assignment-self')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '00482a5a-887f-4fb3-b363-3b7fe8e74483')
    principalId: '401398df-e645-48a9-ac20-27295d890559' //This is the object id of abid in AD, this is required for creating the secrets
    principalType: 'User'
  }
}

resource secrets 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = [for secret in secretsObject.secrets: {
  name: secret.name
  parent: keyVault
  properties: {
    value: secret.value
  }
}]

output name string = keyVault.name
