@description('Private IP of firewall to use as next hop IP')
param firewallPrivIp string

var addressPrefix = '10.30.0.0/16'

resource appProdSpokeRoute 'Microsoft.Network/routeTables@2023-11-01' = {
  name: 'appProdSpokeRoute'
  location: 'uksouth'
  properties: {
    disableBgpRoutePropagation: true
    routes: [
      {
        name: 'appProdSpokeRoute'
        properties: {
          addressPrefix: addressPrefix
          hasBgpOverride: true
          nextHopIpAddress: firewallPrivIp
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
  }
}

output appProdSpokeRouteId string = appProdSpokeRoute.id
