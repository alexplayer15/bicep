//-----------CORE NETWORK PARAMS---------//

@description('Name of the VNET')
param virtualCoreNetworkName string = 'vnet-core'

@description('Name of the subnet in the virtual network')
param vmSubnetName string = 'vm-spokeSubnet'

@description('Route table ID for subnet')
param routeTableId string

var subnetKeyVaultAddressPrefix = '10.20.2.0/24'
var vmSubnetAddressPrefix = '10.20.1.0/24'
var coreVnetaddressPrefix = '10.20.0.0/16'
var location = resourceGroup().location

//----CORE RESOURCES----//
resource virtualCoreNetwork 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: virtualCoreNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        coreVnetaddressPrefix
      ]
    }
    subnets: [
      {
        name: vmSubnetName
        properties: {
          addressPrefix: vmSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        routeTable: {
          id: routeTableId
       }
      }
    }
      {
        name: 'azureKeyVaultSubnet'
        properties: {
          addressPrefix: subnetKeyVaultAddressPrefix
        routeTable: {
            id: routeTableId
         }
        } 
    }
    ]
  }
}

output coreVnetResource string = resourceId('Microsoft.Network/virtualNetworks', virtualCoreNetworkName)
output coreVnetId string = virtualCoreNetwork.id
output vmSubnetId string = virtualCoreNetwork.properties.subnets[0].id
output corevVnetName string = virtualCoreNetworkName
output subnetKeyVaultName string = virtualCoreNetwork.properties.subnets[1].name
