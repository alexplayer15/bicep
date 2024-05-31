@description('Name of the hub VNet')
param virtualNetworkName string = 'vm-hubNet'

@description('Name of the bastion subnet in the hub virtual network')
param subnetName string = 'AzureBastionSubnet'

@description('Private DNS Zone Name for Web App')
param privateDnsZoneAppName string = 'privatelink.azurewebsites.net'

@description('Private DNS Zone Name for SQL DBs')
var privateDnsSqlZoneName = 'privatelink${environment().suffixes.sqlServerHostname}'

@description('Private DNS Zone Name for SQL DBs')
var blobPrivateDnsZoneName = 'privatelink.blob.${environment().suffixes.storage}'

@description('Private DNS Zone Name for Key Vault')
var privateDNSZoneKeyVaultName = 'privatelink${environment().suffixes.keyvaultDns}'

var bastionSubnetAddressPrefix = '10.2.0.0/26'
var firewallSubnetAddressPrefix = '10.2.1.0/26'
var addressPrefix = '10.2.0.0/16'
var location = 'uksouth'

resource virtualHubNetwork 'Microsoft.Network/virtualNetworks@2023-09-01' = {
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
          addressPrefix: bastionSubnetAddressPrefix
        }
      }
        {
          name: 'AzureFirewallSubnet'
          properties: {
            addressPrefix: firewallSubnetAddressPrefix
          } 
      }
    ]
  }
}

resource privateDnsAppZones 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDnsZoneAppName
  location: 'global'
}

resource privateDnsZoneAppLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateDnsAppZones
  name: '${privateDnsAppZones.name}-link'
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

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsSqlZone
  name: '${privateDnsSqlZoneName}-link'
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

resource blobPrivateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${blobPrivateDnsZoneName}-link'
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
  name: '${privateDNSZoneKeyVaultName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualHubNetwork.id
    }
  }
}

output subnetBastionId string = virtualHubNetwork.properties.subnets[0].id
output firewallSubnetId string = virtualHubNetwork.properties.subnets[1].id
