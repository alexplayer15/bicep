@description('Name of the VNet')
param virtualNetworkName string = 'app-prod-vnet'

@description('Route table ID for UDR to firewall')
param appProdSpokeRouteId string

@description('Name of the Web Farm')
param serverFarmName string = 'app-bicep-prod-farm'

@description('Web App 1 name must be unique DNS name worldwide')
param site1_Name string = 'webapp1Prod-${uniqueString(resourceGroup().id)}'

@description('CIDR of your VNet')
param virtualNetwork_CIDR string = '10.30.0.0/16'

@description('Name of the subnet')
param subnet1Name string = 'app-prod-subnet'

@description('Name of the subnet')
param subnet2Name string = 'sql-prod-subnet'

@description('Name of the subnet')
param subnet3Name string = 'storage-prod-subnet'

@description('CIDR of your subnet')
param subnet1_CIDR string = '10.30.1.0/24'

@description('CIDR of your subnet')
param subnet2_CIDR string = '10.30.2.0/24'

@description('CIDR of your subnet')
param subnet3_CIDR string = '10.30.3.0/24'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('SKU name, must be minimum P1v2')
@allowed([
  'P1v2'
  'P2v2'
  'P3v2'
])
param skuName string = 'P1v2'

@description('SKU size, must be minimum P1v2')
@allowed([
  'P1v2'
  'P2v2'
  'P3v2'
])
param skuSize string = 'P1v2'

@description('SKU family, must be minimum P1v2')
@allowed([
  'P1v2'
  'P2v2'
  'P3v2'
])
param skuFamily string = 'P1v2'

@description('Name of your Private Endpoint')
param privateEndpointName string = 'PrivateEndpointProd'

@description('Link name between your Private Endpoint and your Web App')
param privateLinkConnectionName string = 'PrivateEndpointLinkProd'

var webapp_dns_name = '.azurewebsites.net'
var privateDNSZoneName = 'privatelink.azurewebsites.net'
var SKU_tier = 'PremiumV2'

@description('DNS Group Name')
param privateDnsGroupName string = 'mydnsgroupname'

resource appProdVirtualNetwork 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetwork_CIDR
      ]
    }
    subnets: [
      {
        name: subnet1Name
        properties: {
          addressPrefix: subnet1_CIDR
          privateEndpointNetworkPolicies: 'Disabled'
          routeTable: {
            id: appProdSpokeRouteId
         }
        }
      }
      {
        name: subnet2Name
        properties: {
          addressPrefix: subnet2_CIDR
          privateEndpointNetworkPolicies: 'Enabled'
          routeTable: {
            id: appProdSpokeRouteId
         }
        }
      }
      {
        name: subnet3Name
        properties: {
          addressPrefix: subnet3_CIDR
          privateEndpointNetworkPolicies: 'Enabled'
          routeTable: {
            id: appProdSpokeRouteId
         }
        }
      }
    ]
  }
}

resource serverFarm 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: serverFarmName
  location: location
  sku: {
    name: skuName
    tier: SKU_tier
    size: skuSize
    family: skuFamily
    capacity: 1
  }
  kind: 'app'
}

resource webApp1 'Microsoft.Web/sites@2022-03-01' = {
  name: site1_Name
  location: location
  kind: 'app'
  properties: {
    serverFarmId: serverFarm.id
  }
}

resource webApp1Config 'Microsoft.Web/sites/config@2020-06-01' = {
  parent: webApp1
  name: 'web'
  properties: {
    ftpsState: 'AllAllowed'
  }
}

resource webApp1Binding 'Microsoft.Web/sites/hostNameBindings@2019-08-01' = {
  parent: webApp1
  name: '${webApp1.name}${webapp_dns_name}'
  properties: {
    siteName: webApp1.name
    hostNameType: 'Verified'
  }
}


resource privateEndpoint 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets',appProdVirtualNetwork.name ,subnet1Name)
    }
    privateLinkServiceConnections: [
      {
        name: privateLinkConnectionName
        properties: {
          privateLinkServiceId: webApp1.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' existing = {
  name: privateDNSZoneName
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  parent: privateEndpoint
  name: privateDnsGroupName
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}


output appProdVirtualNetworkId string = appProdVirtualNetwork.id
output sqlSubnetId string = appProdVirtualNetwork.properties.subnets[1].id
output storageSubnetId string = appProdVirtualNetwork.properties.subnets[2].id
