
resource appProdVirtualNetwork 'Microsoft.Network/virtualNetworks@2022-09-01' existing = {
  name: 'app-prod-vnet'
}

resource virtualHubNetwork 'Microsoft.Network/virtualNetworks@2022-09-01' existing = {
  name: 'vm-hubNet'
}

resource virtualVmSpokeNetwork 'Microsoft.Network/virtualNetworks@2022-09-01' existing = {
  name: 'vm-spokeNet'
}

resource appDevVirtualNetwork 'Microsoft.Network/virtualNetworks@2022-09-01' existing = {
  name: 'app-dev-vnet'
}

resource vmSpokeToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: 'spoke-to-hub'
  parent: virtualVmSpokeNetwork
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: true
    remoteVirtualNetwork: {
      id: virtualHubNetwork.id
    }
  }
}

resource hubtoVmSpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: 'hub-to-spoke'
  parent: virtualHubNetwork
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: true
    remoteVirtualNetwork: {
      id: virtualVmSpokeNetwork.id
    }
  }
}

resource appDevSpokeToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: 'app-dev-to-hub'
  parent: appDevVirtualNetwork
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: true
    remoteVirtualNetwork: {
      id: virtualHubNetwork.id
    }
  }
}

resource hubToAppDevSpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: 'hub-to-app-dev-spoke'
  parent: virtualHubNetwork
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: true
    remoteVirtualNetwork: {
      id: appDevVirtualNetwork.id
    }
  }
}

resource appProdSpokeToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: 'app-prod-to-hub'
  parent: appProdVirtualNetwork
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: true
    remoteVirtualNetwork: {
      id: virtualHubNetwork.id
    }
  }
}

resource hubToAppProdSpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: 'hub-to-app-prod-spoke'
  parent: virtualHubNetwork
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: true
    remoteVirtualNetwork: {
      id: appProdVirtualNetwork.id
    }
  }
}
