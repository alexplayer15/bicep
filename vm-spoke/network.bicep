@description('Name of the VNET')
param virtualNetworkName string = 'vm-spokeNet'

@description('Name of the subnet in the virtual network')
param subnetName string = 'vm-spokeSubnet'

@description('Route table ID for subnet')
param vmSpokeRouteId string

var subnetAddressPrefix = '10.1.0.0/24'
var addressPrefix = '10.1.0.0/16'
var location = 'uksouth'


resource virtualVmSpokeNetwork 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        routeTable: {
          id: vmSpokeRouteId
       }
      }
     }
    ]
  }
}

output vnetResource string = resourceId('Microsoft.Network/virtualNetworks', virtualNetworkName)
output subnetId string = virtualVmSpokeNetwork.properties.subnets[0].id
