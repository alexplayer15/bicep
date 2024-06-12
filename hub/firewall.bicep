param firewallName string = 'firewallBicep'

@description('Subnet ID for firewall subnet')
param firewallSubnetId string

@description('Location for all resources.')
param location string = resourceGroup().location
param firewallPolicyName string = '${firewallName}-Policy'

param logAnalyticsWorkspaceId string

var azurepublicIpname = 'pip-firewall'
var azureFirewallPublicIpId = publicIpAddressForFirewall.id

resource publicIpAddressForFirewall 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: azurepublicIpname
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2022-01-01'= {
  name: firewallPolicyName
  location: location
  properties: {
    threatIntelMode: 'Alert'
  }
}

resource networkRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2022-01-01' = {
  parent: firewallPolicy
  name: 'DefaultNetworkRuleCollectionGroup'
  properties: {
    priority: 150
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        name: 'allow-all'
        priority: 150
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'allow-all'
            ipProtocols: [
              'Any'
            ]
            sourceAddresses: [
              '*'
            ]
            destinationAddresses: [
              '*'
            ]
            destinationPorts: [ 
              '*'
            ]
          }
        ]
      }
    ]
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2021-03-01' = {
  name: firewallName
  location: location
  dependsOn: [
    networkRuleCollectionGroup
  ]
  properties: {
    ipConfigurations: [
      {
        name: 'publicIpConfiguration'
        properties: {
          subnet: {
            id: firewallSubnetId
          }
          publicIPAddress: {
            id: azureFirewallPublicIpId
          }
        }
      }
    ]
    firewallPolicy: {
      id: firewallPolicy.id
    }
  }
}

resource firewallDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${firewallName}-diagnostic'
  scope: firewall
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AzureFirewallApplicationRule'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'AzureFirewallNetworkRule'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'AzureFirewallDnsProxy'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
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


output firewallPrivateIP string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
output firewall object = firewall
output firewallName string = firewall.name
