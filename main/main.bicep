module network '../vm-spoke/network.bicep' = {
  name: 'vnetModule'
  dependsOn: [
    udrVmSpoke
  ]
  params: {
    vmSpokeRouteId: udrVmSpoke.outputs.vmSpokeRouteId
  }
}

module hubNetwork '../hub/network.bicep' = {
  name: 'hubNetworkModule'
}

// module vm '../vm-spoke/vm.bicep' = {
//   name: 'vmModule'
//   params: {
//     adminPasswordOrKey: resourceGroup().name
//     subnetId: network.outputs.subnetId
//   }
// }


// module bastion '../hub/bastion.bicep' = {
//   name: 'bastionModule'
//   params: {
//    subnetBastionId: hubNetwork.outputs.subnetBastionId
//   }
// }

module firewall '../hub/firewall.bicep' = {
  name: 'firewallModule'
  params: {
    firewallSubnetId: hubNetwork.outputs.firewallSubnetId
  }
}

module udrVmSpoke '../vm-spoke/routeTable.bicep' = {
  name: 'udrVmSpoke'
  dependsOn: [
    firewall
  ]
  params: {
    firewallPrivIp: firewall.outputs.firewallPrivateIP
  }
}

module udrAppDev '../dev-app-spoke/routeTable.bicep' = {
  name: 'udrAppDevModule'
  params: {
    firewallPrivIp: firewall.outputs.firewallPrivateIP
  }
}

module appDevNetwork '../dev-app-spoke/app-dev.bicep' = {
  name: 'appDevSpokeModule'
  dependsOn: [
    udrAppDev
    hubNetwork
  ]
  params: {
    appDevSpokeRouteId: udrAppDev.outputs.appDevSpokeRouteId
  }
}

module sqlServer '../dev-app-spoke/sql.bicep' = {
  name: 'sqlServerDevModule'
  dependsOn: [
    appDevNetwork
    hubNetwork
  ]
  params: {
    subnet2Id: appDevNetwork.outputs.sqlSubnetId
    sqlAdministratorLoginPassword: resourceGroup().name
  }
}

module storage '../dev-app-spoke/storage.bicep' = {
  name: 'storageDevModule'
  dependsOn: [
    appDevNetwork
    hubNetwork
  ]
  params: {
    storageSubnetId: appDevNetwork.outputs.storageSubnetId

  }
}

module udrAppProd '../prod-app-spoke/routeTable.bicep' = {
  name: 'udrAppProdModule'
  params: {
    firewallPrivIp: firewall.outputs.firewallPrivateIP
  }
}

module appProdNetwork '../prod-app-spoke/app-prod.bicep' = {
  name: 'appProdSpokeModule'
  dependsOn: [
    udrAppProd
    hubNetwork
  ]
  params: {
    appProdSpokeRouteId: udrAppProd.outputs.appProdSpokeRouteId
  }
}

module sqlServerProd '../prod-app-spoke/sql-prod.bicep' = {
  name: 'sqlServerProdModule'
  dependsOn: [
    appProdNetwork
    hubNetwork
  ]
  params: {
    subnet2Id: appProdNetwork.outputs.sqlSubnetId
    sqlAdministratorLoginPassword: resourceGroup().name
  }
}

module storageProd '../prod-app-spoke/storage-prod.bicep' = {
  name: 'storageProdModule'
  dependsOn: [
    appProdNetwork
    hubNetwork
  ]
  params: {
    storageSubnetId: appProdNetwork.outputs.storageSubnetId

  }
}

module peerings '../peering/peering.bicep' = {
  name: 'peeringModule'
  dependsOn: [
    hubNetwork
    appDevNetwork
    appProdNetwork
    network
  ]
}
