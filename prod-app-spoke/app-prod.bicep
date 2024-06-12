@description('Name of the VNet')
param virtualNetworkName string = 'app-prod-vnet'

@description('Route table ID for UDR to firewall')
param appProdSpokeRouteId string

@description('The name of the site.')
param sitesElasticAppProjectName string = 'ElasticAppProject'

@description('The name of the server farm.')
param serverfarms_ASP_rgalexp_beda_name string = 'ASP-rgalexp-beda'

@description('The external ID of the server farm.')
param serverfarms_ASP_rgalexp_beda_externalid string = '/subscriptions/e5cfa658-369f-4218-b58e-cece3814d3f1/resourceGroups/rg-alexp/providers/Microsoft.Web/serverfarms/ASP-rgalexp-beda'

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

@description('Name of your Private Endpoint')
param privateEndpointName string = 'PrivateEndpointProd'

@description('Link name between your Private Endpoint and your Web App')
param privateLinkConnectionName string = 'PrivateEndpointLinkProd'

var webapp_dns_name = '.azurewebsites.net'
var privateDNSZoneName = 'privatelink.azurewebsites.net'

@description('DNS Group Name')
param privateDnsGroupName string = 'mydnsgroupname'

param appInsightName string = 'webAppProdInsights'

@description('Private DNS Zone Name for Web App')
param privateDnsZoneAppName string = 'privatelink.azurewebsites.net'

param coreVirtualNetworkId string

param logAnalyticsWorkspaceId string

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

resource serverFarm 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: serverfarms_ASP_rgalexp_beda_name
  location: 'UK South'
  sku: {
    name: 'P0v3'
    tier: 'Premium0V3'
    size: 'P0v3'
    family: 'Pv3'
    capacity: 1
  }
  kind: 'linux'
  properties: {
    perSiteScaling: false
    elasticScaleEnabled: false
    maximumElasticWorkerCount: 1
    isSpot: false
    reserved: true
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    zoneRedundant: false
  }
}

resource webAppProd 'Microsoft.Web/sites@2023-12-01' = {
  name: sitesElasticAppProjectName
  location: location
  kind: 'app,linux,container'
  dependsOn: [
    serverFarm
  ]
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: 'elasticappproject.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: 'elasticappproject.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: serverfarms_ASP_rgalexp_beda_externalid
    reserved: true
    isXenon: false
    hyperV: false
    dnsConfiguration: {}
    vnetRouteAllEnabled: false
    vnetImagePullEnabled: false
    vnetContentShareEnabled: false
    siteConfig: {
      numberOfWorkers: 1
      acrUseManagedIdentityCreds: false
      alwaysOn: true
      http20Enabled: false
      functionAppScaleLimit: 0
      minimumElasticInstanceCount: 1
      linuxFxVersion: 'DOCKER|alexplayer15/elastic-app:test'
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
      ]
    }
    scmSiteAlsoStopped: false
    clientAffinityEnabled: false
    clientCertEnabled: false
    clientCertMode: 'Required'
    hostNamesDisabled: false
    vnetBackupRestoreEnabled: false
    customDomainVerificationId: '20E80D1BA67168EAC63884C4D8A72C3CD1EFD4E02FBB3687C96AA3E672E7C1B0'
    containerSize: 0
    dailyMemoryTimeQuota: 0
    httpsOnly: true
    redundancyMode: 'None'
    publicNetworkAccess: 'Enabled'
    storageAccountRequired: false
    keyVaultReferenceIdentity: 'SystemAssigned'
  }
}

resource ftpPolicy 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2023-12-01' = {
  name: 'ftp'
  parent: webAppProd
  properties: {
    allow: false
  }
}

resource scmPolicy 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2023-12-01' = {
  name: 'scm'
  parent: webAppProd
  properties: {
    allow: false
  }
}

resource siteConfig 'Microsoft.Web/sites/config@2023-12-01' = {
  name: 'web'
  parent: webAppProd
  properties: {
    numberOfWorkers: 1
    defaultDocuments: [
      'Default.htm'
      'Default.html'
      'Default.asp'
      'index.htm'
      'index.html'
      'iisstart.htm'
      'default.aspx'
      'index.php'
      'hostingstart.html'
    ]
    netFrameworkVersion: 'v4.0'
    requestTracingEnabled: false
    remoteDebuggingEnabled: false
    remoteDebuggingVersion: 'VS2019'
    httpLoggingEnabled: false
    acrUseManagedIdentityCreds: false
    logsDirectorySizeLimit: 35
    detailedErrorLoggingEnabled: false
    publishingUsername: '$ElasticAppProject'
    scmType: 'VSTSRM'
    use32BitWorkerProcess: true
    webSocketsEnabled: false
    alwaysOn: true
    managedPipelineMode: 'Integrated'
    virtualApplications: [
      {
        virtualPath: '/'
        physicalPath: 'site\\wwwroot'
        preloadEnabled: true
      }
    ]
    loadBalancing: 'LeastRequests'
    experiments: {
      rampUpRules: []
    }
    autoHealEnabled: false
    vnetRouteAllEnabled: false
    vnetPrivatePortsCount: 0
    publicNetworkAccess: 'Enabled'
    localMySqlEnabled: false
    ipSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 2147483647
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 2147483647
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictionsUseMain: false
    http20Enabled: false
    minTlsVersion: '1.2'
    scmMinTlsVersion: '1.2'
    ftpsState: 'FtpsOnly'
    preWarmedInstanceCount: 0
    elasticWebAppScaleLimit: 0
    functionsRuntimeScaleMonitoringEnabled: false
    minimumElasticInstanceCount: 1
    linuxFxVersion: 'DOCKER|alexplayer15/elastic-app:test'
    azureStorageAccounts: {}
  }
}

resource appServiceAppSettings 'Microsoft.Web/sites/config@2020-06-01' = {
  parent: webAppProd
  name: 'logs'
  properties: {
    applicationLogs: {
      fileSystem: {
        level: 'Information'
      }
    }
    httpLogs: {
      fileSystem: {
        retentionInMb: 40
        enabled: true
      }
    }
    failedRequestsTracing: {
      enabled: true
    }
    detailedErrorMessages: {
      enabled: true
    }
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightName
  location: 'uksouth'
  kind: 'string'
  tags: {
    displayName: 'AppInsight'
    ProjectName: sitesElasticAppProjectName
  }
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspaceId
  }
}

// resource appServiceLogging 'Microsoft.Web/sites/config@2020-06-01' = {
//   parent: webAppProd
//   name: 'appsettings'
//   properties: {
//     APPINSIGHTS_INSTRUMENTATIONKEY: appInsights.properties.InstrumentationKey
//   }
//   dependsOn: [
//     appServiceSiteExtension
//   ]
// }

// resource appServiceSiteExtension 'Microsoft.Web/sites/siteextensions@2020-06-01' = {
//   parent: webAppProd
//   name: 'Microsoft.ApplicationInsights.AzureWebSites'
//   dependsOn: [
//     appInsights
//   ]
// }

resource deployment 'Microsoft.Web/sites/deployments@2023-12-01' = {
  name: '${sitesElasticAppProjectName}-2311717931349466'
  parent: webAppProd
  properties: {
    status: 4
    author: 'Alexander Player'
    deployer: 'VSTS'
    message: '{"type":"Deployment","commitId":"7b5f6ecf4315c26f5d94b9c74796e6519a2a70e7","buildId":"231","buildNumber":"20240609.1","repoProvider":"GitHub","repoName":"alexplayer15/elastic-app","collectionUrl":"https://dev.azure.com/AlexanderPlayer/","teamProject":"3c77fdbc-cb72-4bf9-8d8b-e203c89c5df4","buildProjectUrl":"https://dev.azure.com/AlexanderPlayer/3c77fdbc-cb72-4bf9-8d8b-e203c89c5df4","repositoryUrl":"https://github.com/alexplayer15/elastic-app","branch":"dev","teamProjectName":"elastic-app","slotName":"production"}'
    start_time: '2024-06-09T11:09:10.0204678Z'
    end_time: '2024-06-09T11:09:10.0204678Z'
    active: true
  }
}

resource hostNameBinding 'Microsoft.Web/sites/hostNameBindings@2023-12-01' = {
  name: '${sitesElasticAppProjectName}${webapp_dns_name}'
  parent: webAppProd
  properties: {
    siteName: webAppProd.name
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
          privateLinkServiceId: webAppProd.id
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

resource appPrivateDnsZoneProdVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${privateDnsZoneAppName}-prodLink'
  parent: privateDnsZone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: appProdVirtualNetwork.id
    }
  }
}

resource appPrivateDnsZoneCoreVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${privateDnsZoneAppName}-coreLink'
  parent: privateDnsZone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: coreVirtualNetworkId
    }
  }
}


output appProdVirtualNetworkId string = appProdVirtualNetwork.id
output sqlSubnetId string = appProdVirtualNetwork.properties.subnets[1].id
output storageSubnetId string = appProdVirtualNetwork.properties.subnets[2].id
output webAppProdName string = webAppProd.name
output appProdVirtualNetworkName string = appProdVirtualNetwork.name
