param resourcePrefix string

resource frontDoorProfile 'Microsoft.Cdn/profiles@2023-05-01' = {
  name: '${resourcePrefix}-profile'
  location: 'global'
  sku: {
    name: 'Standard_AzureFrontDoor'
  }
}

output id string = frontDoorProfile.properties.frontDoorId
