@description('App Service location. Default is the location of the resource group.')
param location string = resourceGroup().location

param virtualNetworkName string 

param subnetName string 

@description('Environment Name.')
param envName string = 'prod'

@description('Default FQDN to be used to access MyApp')
param site_FQDN string = 'ElasticAppProject.azurewebsites.net'

param webAppProdName string = 'ElasticAppProject'

var publicIPAddressName = 'pip-${webAppProdName}-${envName}-${location}-0010'
var applicationGateWayName = 'apgw-${webAppProdName}-${envName}-${location}-001'
var management_resourcegroup = resourceGroup().name

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: publicIPAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource applicationGateWay 'Microsoft.Network/applicationGateways@2021-05-01' = {
  name: applicationGateWayName
  location: location
  identity: {
      type: 'None'
  }
  dependsOn: [
    publicIPAddress
  ]
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
    }
    autoscaleConfiguration: {
      minCapacity: 1
      maxCapacity: 10
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig-${envName}'
        properties: {
          subnet: {
            id: resourceId(management_resourcegroup, 'Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIp-${envName}'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', publicIPAddressName)
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
      {
        name: 'port_5001'
        properties: {
          port: 5001
        }

      }
    ]
    backendAddressPools: [
      {
        name: 'MyApp-BackendPool-${envName}'
        properties: {
          backendAddresses: [
            {
              fqdn: site_FQDN
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'BackendHttpSettings-${envName}'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          requestTimeout: 600
        }
      }
      {
        name: 'BackendAppSettings-${envName}'
        properties: {
          port: 5001
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          requestTimeout: 600
        }
      }
    ]
    httpListeners: [
      {
        name: 'MyApp-${envName}-listener-port80'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGateWayName, 'appGwPublicFrontendIp-${envName}')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGateWayName, 'port_80')
          }
          protocol: 'Http'
          requireServerNameIndication: false

        }
      }
      {
        name: 'MyApp-${envName}-listener-port5001'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGateWayName, 'appGwPublicFrontendIp-${envName}')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGateWayName, 'port_5001')
          }
          protocol: 'Http'
          requireServerNameIndication: false

        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'myRoutingRuleHttp'
        properties: {
          ruleType: 'Basic'
          priority: 10
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGateWayName, 'MyApp-${envName}-listener-port80')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGateWayName, 'MyApp-BackendPool-${envName}')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGateWayName, 'BackendHttpSettings-${envName}')
          }
        }
      }
      {
        name: 'myRoutingRuleApp'
        properties: {
          ruleType: 'Basic'
          priority: 20
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGateWayName, 'MyApp-${envName}-listener-port5001')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGateWayName, 'MyApp-BackendPool-${envName}')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGateWayName, 'BackendAppSettings-${envName}')
          }
        }
      }
    ]
    redirectConfigurations: [
      {
        name: 'httpToSignupRedirect'
        properties: {
          redirectType: 'Permanent'
          targetUrl: 'http://${site_FQDN}/signup'
        }
      }
    ]
  }
}
