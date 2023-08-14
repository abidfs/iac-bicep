param resourcePrefix string
param hostName string

resource frontDoorProfile 'Microsoft.Cdn/profiles@2023-05-01' existing = {
  name: '${resourcePrefix}-profile'
}

resource endpoint 'Microsoft.Cdn/profiles/afdEndpoints@2023-05-01' = {
  parent: frontDoorProfile
  name: '${resourcePrefix}-endpoint'
  location: 'global'
  properties: {
    enabledState: 'Enabled'
  }
}

resource frontDoorOriginGroup 'Microsoft.Cdn/profiles/originGroups@2023-05-01' = {
  name: '${resourcePrefix}-origin-group'
  parent: frontDoorProfile
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Http'
      probeIntervalInSeconds: 100
    }
  }
}

resource frontDoorOrigin 'Microsoft.Cdn/profiles/originGroups/origins@2023-05-01' = {
  name: '${resourcePrefix}-origin'
  parent: frontDoorOriginGroup
  properties: {
    hostName: hostName
    httpPort: 80
    httpsPort: 443
    originHostHeader: hostName
    priority: 1
    weight: 1000
  }
}

resource frontDoorRoute 'Microsoft.Cdn/profiles/afdEndpoints/routes@2023-05-01' = {
  name: '${resourcePrefix}-route'
  parent: endpoint
  dependsOn: [
    frontDoorOrigin
  ]
  properties: {
    originGroup: {
      id: frontDoorOriginGroup.id
    }
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'HttpsOnly'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
  }
}
