@description('Private IP of firewall to use as next hop IP')
param firewallPrivIp string

var addressPrefix = '10.31.0.0/16'

resource appDevSpokeRoute 'Microsoft.Network/routeTables@2023-11-01' = {
  name: 'appDevSpokeRoute'
  location: 'uksouth'
  properties: {
    disableBgpRoutePropagation: true
    routes: [
      {
        name: 'appDevSpokeRoute'
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

output appDevSpokeRouteId string = appDevSpokeRoute.id
