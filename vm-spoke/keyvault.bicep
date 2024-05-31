@description('Spoke VNet name')
param virtualNetworkName string

@description('Spoke subnet name')
param subnetName string

param privateEndpointName string = 'keyVaultPrivateEndpoint'

param location string = resourceGroup().location

@description('Link name between your Private Endpoint and Keyvault')
param privateLinkConnectionName string = 'PrivateEndpointLinkKeyVault'

var privateDNSZoneName = 'privatelink${environment().suffixes.keyvaultDns}'

resource keyvaultCore 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-bicep-core'
  location: resourceGroup().location
  properties: {
    accessPolicies: [
      {
        applicationId: '1271d97c-4e1f-4927-9fcd-cefdbf3650f6'
        objectId: '21d023f4-cf66-4a7e-a44d-ed970f4db6ab'
        permissions: {
          keys: [
            'all'
          ]
          secrets: [
            'all'
          ]
        }
        tenantId: 'd4003661-f87e-4237-9a9b-8b9c31ba2467'
      }
    ]
    createMode: 'default'
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    enablePurgeProtection: true
    enableRbacAuthorization: true
    enableSoftDelete: false
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
      ipRules: [
        {
          value: '0.0.0.0/0'
        }
      ]
    }
    publicNetworkAccess: 'disabled'
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: 'd4003661-f87e-4237-9a9b-8b9c31ba2467'
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets',virtualNetworkName ,subnetName)
    }
    privateLinkServiceConnections: [
      {
        name: privateLinkConnectionName
        properties: {
          privateLinkServiceId: keyvaultCore.id
          groupIds: [
            'vault'
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
  name: 'dnsgroupname'
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
