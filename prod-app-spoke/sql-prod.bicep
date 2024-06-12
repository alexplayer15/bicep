@description('The administrator username of the SQL logical server')
param sqlAdministratorLogin string = 'azureuser'

@description('The administrator password of the SQL logical server.')
@secure()
param sqlAdministratorLoginPassword string

@description('Subnet hosting SQL DB')
param subnet2Id string

@description('Location for all resources.')
param location string = resourceGroup().location

param appProdVirtualNetworkId string
param coreVirtualNetworkId string

var sqlServerName = 'sqlserverProd${uniqueString(resourceGroup().id)}'
var databaseName = '${sqlServerName}/sample-db'
var privateEndpointName = 'sqlDbPrivateEndpointProd'
var sqlPrivateDnsZoneName = 'privatelink${environment().suffixes.sqlServerHostname}'
var pvtEndpointDnsGroupName = 'mydnsgroupname'


resource sqlServer 'Microsoft.Sql/servers@2021-11-01-preview' = {
  name: sqlServerName
  location: location
  tags: {
    displayName: sqlServerName
  }
  properties: {
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorLoginPassword
    version: '12.0'
    publicNetworkAccess: 'Disabled'
  }
}

resource database 'Microsoft.Sql/servers/databases@2021-11-01-preview' = {
  name: databaseName
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
  tags: {
    displayName: databaseName
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 104857600
    sampleName: 'AdventureWorksLT'
  }
  dependsOn: [
    sqlServer
  ]
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: subnet2Id
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: sqlServer.id
          groupIds: [
            'sqlServer'
          ]
        }
      }
    ]
  }
}

resource sqlPrivateDnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' existing = {
  name: sqlPrivateDnsZoneName
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  parent: privateEndpoint
  name: pvtEndpointDnsGroupName
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: sqlPrivateDnsZone.id
        }
      }
    ]
  }
}

resource sqlPrivateDnsZoneProdLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: sqlPrivateDnsZone
  name: '${sqlPrivateDnsZoneName}-prodLink'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: appProdVirtualNetworkId
    }
  }
}

resource sqlPrivateDnsZoneCoreLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: sqlPrivateDnsZone
  name: '${sqlPrivateDnsZoneName}-coreLink'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: coreVirtualNetworkId
    }
  }
}
