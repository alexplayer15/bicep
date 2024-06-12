//-----------HUB NETWORK PARAMS---------//

@description('Name of the hub VNet')
param virtualHubNetworkName string = 'vm-hubNet'

param location string = resourceGroup().location

@description('Private DNS Zone Name for Web App')
param privateDnsZoneAppName string = 'privatelink.azurewebsites.net'

@description('Private DNS Zone Name for SQL DBs')
var privateDnsSqlZoneName = 'privatelink${environment().suffixes.sqlServerHostname}'

@description('Private DNS Zone Name for SQL DBs')
var blobPrivateDnsZoneName = 'privatelink.blob.${environment().suffixes.storage}'

@description('Private DNS Zone Name for Key Vault')
var privateDNSZoneKeyVaultName = 'privatelink${environment().suffixes.keyvaultDns}'

param bastionSubnetAddressPrefix string = '10.2.0.0/26'
param firewallSubnetAddressPrefix string = '10.2.1.0/26'
param appGatewayAddressPrefix string = '10.2.2.0/24'
param hubVnetAddressPrefix string= '10.2.0.0/16'

var bastionSubnetName = 'AzureBastionSubnet'
var firewallSubnetName = 'AzureFirewallSubnet'
param appGwSubnetName string = 'appGwSubnet'

//----Hub Resources-----//

resource virtualHubNetwork 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: virtualHubNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubVnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: bastionSubnetAddressPrefix
        }
      }
        {
          name: firewallSubnetName
          properties: {
            addressPrefix: firewallSubnetAddressPrefix
          } 
      }
      {
        name: appGwSubnetName
        properties: {
          addressPrefix: appGatewayAddressPrefix
        } 
    }
    ]
  }
}

//-----DNS SETTINGS-----//

resource privateDnsAppZones 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDnsZoneAppName
  location: 'global'
}

resource privateDnsZoneAppLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateDnsAppZones
  name: '${privateDnsAppZones.name}-hubLink'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualHubNetwork.id
    }
  }
}

resource privateDnsSqlZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsSqlZoneName
  location: 'global'
  properties: {}
}

resource sqlPrivateDnsZoneHubLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsSqlZone
  name: '${privateDnsSqlZoneName}-hubLink'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualHubNetwork.id
    }
  }
}

resource blobPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: blobPrivateDnsZoneName
  location: 'global'
}

resource blobPrivateDnsZoneHubVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${blobPrivateDnsZoneName}-hubLink'
  parent: blobPrivateDnsZone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualHubNetwork.id
    }
  }
}

resource privateDnsKeyVaultZones 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDNSZoneKeyVaultName
  location: 'global'
}

resource privateDnsZoneKeyVaultLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateDnsKeyVaultZones
  name: '${privateDNSZoneKeyVaultName}-hubLink'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualHubNetwork.id
    }
  }
}

//------HUB OUTPUTS----//
output subnetBastionId string = virtualHubNetwork.properties.subnets[0].id
output firewallSubnetId string = virtualHubNetwork.properties.subnets[1].id
output hubNetworkName string = virtualHubNetwork.name
output gatewaySubnetName string = virtualHubNetwork.properties.subnets[2].name
