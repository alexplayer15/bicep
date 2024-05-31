@description('Private IP of firewall to use as next hop IP')
param firewallPrivIp string

var addressPrefix = '10.1.0.0/16'

resource vmSpokeRoute 'Microsoft.Network/routeTables@2023-11-01' = {
  name: 'vmSpokeRoute'
  location: 'uksouth'
  properties: {
    disableBgpRoutePropagation: true
    routes: [
      {
        name: 'vmSpokeRoute'
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

output vmSpokeRouteId string = vmSpokeRoute.id
