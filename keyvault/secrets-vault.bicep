resource keyvaultCore 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-bicep-secrets'
  location: resourceGroup().location
  properties: {
    accessPolicies: [
      {
        objectId: '665c6826-0669-4a90-8273-010e76ac59b3'
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
    enableRbacAuthorization: false
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
    publicNetworkAccess: 'enabled'
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: 'd4003661-f87e-4237-9a9b-8b9c31ba2467'
  }
}


