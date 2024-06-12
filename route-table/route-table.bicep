@description('Private IP of firewall to use as next hop IP')
param firewallPrivIp string

@description('VNet CIDR range for the core network hosting VM')
param coreAddressPrefix string = '10.20.0.0/16'

@description('VNet CIDR for the network hosting dev env')
param appDevAddressPrefix string = '10.31.0.0/16'

@description('VNet CIDR for the network hosting prod env')
param appProdAddressPrefix string = '10.30.0.0/16'

var internetPrefix = '0.0.0.0/0'

resource hubAndSpokeRoutes 'Microsoft.Network/routeTables@2023-11-01' = {
  name: 'hub-and-spoke-routes'
  location: 'uksouth'
  properties: {
    disableBgpRoutePropagation: true
    routes: [
      {
        name: 'vmSpokeRoute'
        properties: {
          addressPrefix: coreAddressPrefix
          hasBgpOverride: true
          nextHopIpAddress: firewallPrivIp
          nextHopType: 'VirtualAppliance'
        }
      }
      {
        name: 'internetRoute'
        properties: {
          addressPrefix: internetPrefix
          hasBgpOverride: true
          nextHopIpAddress: firewallPrivIp
          nextHopType: 'VirtualAppliance'
        }
      }
      {
        name: 'appDevSpokeRoute'
        properties: {
          addressPrefix: appDevAddressPrefix
          hasBgpOverride: true
          nextHopIpAddress: firewallPrivIp
          nextHopType: 'VirtualAppliance'
        }
      }
      {
        name: 'appProdSpokeRoute'
        properties: {
          addressPrefix: appProdAddressPrefix
          hasBgpOverride: true
          nextHopIpAddress: firewallPrivIp
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
  }
}

output routeTableId string = hubAndSpokeRoutes.id
