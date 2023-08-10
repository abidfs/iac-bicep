param location string
param resourcePrefix string

// resource nsg 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
//   name: '${resourcePrefix}-allow-vnet-internal-traffic'
//   location: location
//   properties: {
//     securityRules: [
//       {
//         name: '${resourcePrefix}-allow-app-services-vnet-traffic'
//         properties: {
//           description: 'Allow traffic from app services VNet integration subnet'
//           protocol: 'Tcp'
//           sourcePortRange: '*'
//           destinationPortRange: '*'
//           sourceAddressPrefix: '10.0.0.0/24'
//           destinationAddressPrefix: '*'
//           access: 'Allow'
//           priority: 100
//           direction: 'Inbound'
//         }
//       }
//     ]
//   }
// }

resource nsgPrivateEndpointSubnet 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: '${resourcePrefix}-allow-vnet-internal-traffic'
  location: location
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: '${resourcePrefix}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: '${resourcePrefix}-app-services-vnet-integration-subnet'
        properties: {
          addressPrefix: '10.0.0.0/24'
          delegations: [
            {
              name: '${resourcePrefix}-app-services-vnet-integration-subnet-delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
          networkSecurityGroup: {
            id: nsgPrivateEndpointSubnet.id
          }
        }
      }
      {
        name: '${resourcePrefix}-db-private-endpoints-subnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          delegations: [
            {
              name: 'dlg-Microsoft.DBforMySQL-flexibleServers'
              properties: {
                serviceName: 'Microsoft.DBforMySQL/flexibleServers'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          networkSecurityGroup: {
            id: nsgPrivateEndpointSubnet.id
          }
        }
      }
      {
        name: '${resourcePrefix}-kv-private-endpoints-subnet'
        properties: {
          addressPrefix: '10.0.2.0/26'
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          networkSecurityGroup: {
            id: nsgPrivateEndpointSubnet.id
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.KeyVault'
            }
          ]
        }
      }
    ]
  }
}


output virtualNetworkId string = virtualNetwork.id
output vnetIntegrationSubnetId string = virtualNetwork.properties.subnets[0].id
output vnetIntegrationSubnetIpRange string = virtualNetwork.properties.subnets[0].properties.addressPrefix
output dbPrivateEndpointsSubnetId string = virtualNetwork.properties.subnets[1].id
output kvPrivateEndpointsSubnetId string = virtualNetwork.properties.subnets[2].id
