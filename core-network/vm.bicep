@description('The name of your Virtual Machine.')
param vmName string = 'vm-core-001'

@description('Username for the Virtual Machine.')
@secure()
param adminUsername string 

@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'password'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string 

@description('Location for all resources.')
param location string = 'uksouth'

@description('vNet ID from network.bicep module')
param subnetId string 

@description('The size of the VM')
param vmSize string = 'Standard_D2s_v3'

@description('Security Type of the Virtual Machine.')
@allowed([
  'Standard'
  'TrustedLaunch'
])

param securityType string = 'Standard'

param OSVersion string = '2022-datacenter-azure-edition'

param logAnalyticsWorkspaceId string

var networkInterfaceName = '${vmName}NetInt'
var osDiskType = 'Standard_LRS'
var linuxConfiguration = {
  disablePasswordAuthentication: false

}
var securityProfileJson = {
  uefiSettings: {
    secureBootEnabled: true
    vTpmEnabled: true
  }
  securityType: securityType
}
// var extensionName = 'GuestAttestation'
// var extensionPublisher = 'Microsoft.Azure.Security.LinuxAttestation'
// var extensionVersion = '1.0'
// var maaTenantName = 'GuestAttestation'
// var maaEndpoint = substring('emptystring', 0, 0)

resource networkInterface 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    }
  }

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: OSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? null : linuxConfiguration)
    }
    securityProfile: (securityType == 'TrustedLaunch') ? securityProfileJson : null
  }
}

resource azureMonitorAgent 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' = {
  parent: vm
  name: 'AzureMonitorWindowsAgent'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorWindowsAgent'
    typeHandlerVersion: '1.9'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {
      workspaceId: logAnalyticsWorkspaceId
      azureResourceId: vm.id
      stopOnMultipleConnections: true
    }

    protectedSettings: {
      workspaceKey: listkeys(logAnalyticsWorkspaceId, '2022-10-01').primarySharedKey
    }
  }
}

// Define the Data Collection Rule
resource dataCollectionRule 'Microsoft.Insights/dataCollectionRules@2021-04-01' = {
  name: 'bicepVmDataCollectionRule'
  location: location
  properties: {
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: logAnalyticsWorkspaceId
          name: 'la-608256309'
        }
      ]
    }
    dataFlows: [
      {
        destinations: [
          'la-608256309'
        ]
        streams: [
          'Microsoft-Perf'
          'Microsoft-Event'
        ]
      }
    ]
    dataSources: {
      performanceCounters: [
        {
          counterSpecifiers: [
            '*'
          ]
          name: 'bicep-performance-rule'
          samplingFrequencyInSeconds: 60
          streams: [
            'Microsoft-Perf'
          ]
        }
      ]
      windowsEventLogs: [
        {
          name: 'bicep-windows-event-rule'
          streams: [
            'Microsoft-Event'
          ]
          xPathQueries: [
            'System!*[System[(Level=1 or Level=2 or Level=3)]]'
          ]
        }
      ]
    }
  }
}

// Associate the Data Collection Rule with the VM
resource dcrAssociation 'Microsoft.Insights/dataCollectionRuleAssociations@2021-04-01' = {
  name: '${vm.name}-dcrAssociation'
  properties: {
    dataCollectionRuleId: dataCollectionRule.id
    description: 'Association between VM and Data Collection Rule'
  }
  scope: vm
}

// Define the diagnostic settings for the VM
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diagnostics-VM'
  scope: vm
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}

// resource agentExtension 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' = {
//   parent: vm
//   name: 'AzureMonitorAgent'
//   location: location
//   properties: {
//     publisher: 'Microsoft.Azure.Monitor'
//     type: 'AzureMonitorAgent'
//     autoUpgradeMinorVersion: true
//   }
// }


// --------------

// resource vmExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = if (securityType == 'TrustedLaunch' && securityProfileJson.uefiSettings.secureBootEnabled && securityProfileJson.uefiSettings.vTpmEnabled) {
//   parent: vm
//   name: extensionName
//   location: location
//   properties: {
//     publisher: extensionPublisher
//     type: extensionName
//     typeHandlerVersion: extensionVersion
//     autoUpgradeMinorVersion: true
//     enableAutomaticUpgrade: true
//     settings: {
//       AttestationConfig: {
//         MaaSettings: {
//           maaEndpoint: maaEndpoint
//           maaTenantName: maaTenantName
//         }
//       }
//     }
//   }
// }

output vmName string = vm.name
