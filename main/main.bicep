module coreNetwork '../core-network/network.bicep' = {
  name: 'coreVnetModule'
  params: {
    routeTableId: routes.outputs.routeTableId
  }
}

module hubNetwork '../hub/network.bicep' = {
  name: 'hubNetworkModule'
  }

module routes '../route-table/route-table.bicep' = {
  name: 'routeTableModule'
  params: {
    firewallPrivIp: firewall.outputs.firewallPrivateIP
  }
  dependsOn: [
    firewall
  ]
}

module peerings '../peering/peering.bicep' = {
  name: 'peeringModule'
  dependsOn: [
    hubNetwork
    // appDevNetwork
    appProdNetwork
    coreNetwork
  ]
}

resource keyvaultCore 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: 'kv-bicep-secrets'
  scope: resourceGroup('rg-bicep-alp-uks-1')
}

module vm '../core-network/vm.bicep' = {
  name: 'vmModule'
  params: {
    adminUsername: keyvaultCore.getSecret('vmusername')
    adminPasswordOrKey: keyvaultCore.getSecret('vmpassword')
    subnetId: coreNetwork.outputs.vmSubnetId
    logAnalyticsWorkspaceId: logs.outputs.logAnalyticsWorkspaceId
  }
}

module bastion '../hub/bastion.bicep' = {
  name: 'bastionModule'
  params: {
   subnetBastionId: hubNetwork.outputs.subnetBastionId
  }
}

module firewall '../hub/firewall.bicep' = {
  name: 'firewallModule'
  params: {
    firewallSubnetId: hubNetwork.outputs.firewallSubnetId
    logAnalyticsWorkspaceId: logs.outputs.logAnalyticsWorkspaceId
  } 
}

module logs '../logs/logs.bicep' = {
  name: 'logModule'
}

// -------

// module secretsvault '../keyvault/secrets-vault.bicep' = {
//   name: 'secretsVaultModule'
// }

// ---------

module appGateway '../hub/app-gw.bicep' = {
  name: 'appGwModule'
  params: {
    virtualNetworkName: hubNetwork.outputs.hubNetworkName
    subnetName: hubNetwork.outputs.gatewaySubnetName
  }
  dependsOn: [
    appProdNetwork
    hubNetwork
  ]
}

// module keyvault '../core-network/keyvault.bicep' = {
//   name: 'keyVaultModule'
//   params: {
//     virtualNetworkName: coreNetwork.outputs.corevVnetName
//     subnetName: coreNetwork.outputs.subnetKeyVaultName
//     coreNetworkId: coreNetwork.outputs.coreVnetId
//   }
// }

// module appDevNetwork '../dev-app-spoke/app-dev.bicep' = {
//   name: 'appDevSpokeModule'
//   dependsOn: [
//     routes
//     hubNetwork
//   ]
//   params: {
//     appDevSpokeRouteId: routes.outputs.routeTableId
//   }
// }

// module sqlServerDev '../dev-app-spoke/sql.bicep' = {
//   name: 'sqlServerDevModule'
//   dependsOn: [
//     appDevNetwork
//     hubNetwork
//   ]
//   params: {
//     subnet2Id: appDevNetwork.outputs.sqlSubnetId
//     sqlAdministratorLoginPassword: keyvaultCore.getSecret('sqlpassword')
//     appDevVirtualNetworkId: appDevNetwork.outputs.appDevVirtualNetworkId
//   }
// }

// module devStorage '../dev-app-spoke/storage.bicep' = {
//   name: 'storageDevModule'
//   dependsOn: [
//     appDevNetwork
//     hubNetwork
//   ]
//   params: {
//     storageSubnetId: appDevNetwork.outputs.storageSubnetId
//     appDevVirtualNetworkId: appDevNetwork.outputs.appDevVirtualNetworkId

//   }
// }

module appProdNetwork '../prod-app-spoke/app-prod.bicep' = {
  name: 'appProdSpokeModule'
  dependsOn: [
    routes
    hubNetwork
    logs
  ]
  params: {
    appProdSpokeRouteId: routes.outputs.routeTableId
    logAnalyticsWorkspaceId: logs.outputs.logAnalyticsWorkspaceId
    coreVirtualNetworkId: coreNetwork.outputs.coreVnetId
  }
}

// module sqlServerProd '../prod-app-spoke/sql-prod.bicep' = {
//   name: 'sqlServerProdModule'
//   dependsOn: [
//     appProdNetwork
//     hubNetwork
//   ]
//   params: {
//     subnet2Id: appProdNetwork.outputs.sqlSubnetId
//     sqlAdministratorLoginPassword: keyvaultCore.getSecret('sqlpassword')
//     appProdVirtualNetworkId: appProdNetwork.outputs.appProdVirtualNetworkId
//     coreVirtualNetworkId: coreNetwork.outputs.coreVnetId
//   }
// }

// module storageProd '../prod-app-spoke/storage-prod.bicep' = {
//   name: 'storageProdModule'
//   dependsOn: [
//     appProdNetwork
//     hubNetwork
//   ]
//   params: {
//     storageSubnetId: appProdNetwork.outputs.storageSubnetId
//     appProdVirtualNetworkId: appProdNetwork.outputs.appProdVirtualNetworkId
//     coreVirtualNetworkId: coreNetwork.outputs.coreVnetId
//   }
// }

// module recoveryServicesVault '../rsv/rsv.bicep' = {
//   name: 'recoveryServicesModule'
//   params: {
//     existingVirtualMachines: [vm.outputs.vmName]
//     }
//   dependsOn: [
//     vm
//   ]
// }
