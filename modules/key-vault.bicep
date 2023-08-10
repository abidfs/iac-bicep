param location string
param resourcePrefix string
param privateEndpointsSubnetId string
param privateDnsZoneId string
param tenantId string
param principalId string
// param outboundIpAddresses array
@description('Specifies all secrets {"name":"","value":""} wrapped in a secure object.')
@secure()
param secretsObject object

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
      // ipRules: [for outboundIpAddress in outboundIpAddresses: {
      //   value: outboundIpAddress
      // }
      // ]
      // [
      //     {
      //       value: subnetIpRange
      //     }
      //   ]
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

// resource keyVaultPrivateDnsZoneName_link_to_virtualNetwork 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
//   parent: keyVaultPrivateDnsZone
//   name: 'link_to_${toLower(virtualNetworkName)}'
//   location: 'global'
//   properties: {
//     registrationEnabled: false
//     virtualNetwork: {
//       id: vnetId
//     }
//   }
// }

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

//----------------Option1
// resource symbolicname 'Microsoft.KeyVault/vaults/privateEndpointConnections@2022-07-01' = {
//   name: '${resourcePrefix}-keyvault-private-endpoint'
//   parent: keyVault
//   properties: {
//     privateEndpoint: {}
//     privateLinkServiceConnectionState: {
//       actionsRequired: 'None'
//       description: 'Approved as part of infrastructure automation'
//       status: 'Approved'
//     }
//     provisioningState: 'Succeeded'
//   }
// }

//---------------Option2
// resource keyVaultPrivateEndpoint 'Microsoft.Network/privateEndpoints@2022-01-01' = {
//   name: '${resourcePrefix}-keyvault-private-endpoint'
//   location: location
//   properties: {
//     privateLinkServiceConnections: [
//       {
//         name: '${resourcePrefix}-keyvault-private-endpoint'
//         properties: {
//           groupIds: [
//             'vault'
//           ]
//           privateLinkServiceId: keyVault.id
//         }
//       }
//     ]
//     subnet: {
//       id: privateEndpointsSubnetId
//     }
//   }
// }

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
