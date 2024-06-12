@description('Name of the Vault')
param vaultName string ='rsv-bicep'

@description('Change Vault Storage Type (Works if vault has not registered any backup instance)')
@allowed([
  'LocallyRedundant'
  'GeoRedundant'
])
param vaultStorageType string = 'LocallyRedundant'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Backup policy to be used to backup VMs. Backup Policy defines the schedule of the backup and how long to retain backup copies.')
param policyName string = 'DefaultPolicy'

var skuName = 'RS0'
var skuTier = 'Standard'
var scheduleRunTimes = [
  '2017-01-26T05:30:00Z'
]

param existingVirtualMachinesResourceGroup string = 'rg-alexp'

resource recoveryServicesVault 'Microsoft.RecoveryServices/vaults@2022-02-01' = {
  name: vaultName
  location: location
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: {}
}

resource vaultName_vaultstorageconfig 'Microsoft.RecoveryServices/vaults/backupstorageconfig@2022-02-01' = {
  parent: recoveryServicesVault
  name: 'vaultstorageconfig'
  properties: {
    storageModelType: vaultStorageType
  }
}

resource backupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2021-03-01' = {
  parent: recoveryServicesVault
  name: policyName
  location: location
  properties: {
    backupManagementType: 'AzureIaasVM'
    instantRpRetentionRangeInDays: 5
    schedulePolicy: {
      scheduleRunFrequency: 'Daily'
      scheduleRunTimes: scheduleRunTimes
      schedulePolicyType: 'SimpleSchedulePolicy'
    }
    retentionPolicy: {
      dailySchedule: {
        retentionTimes: scheduleRunTimes
        retentionDuration: {
          count: 104
          durationType: 'Days'
        }
      }
      weeklySchedule: {
        daysOfTheWeek: [
          'Sunday'
          'Tuesday'
          'Thursday'
        ]
        retentionTimes: scheduleRunTimes
        retentionDuration: {
          count: 104
          durationType: 'Weeks'
        }
      }
      monthlySchedule: {
        retentionScheduleFormatType: 'Daily'
        retentionScheduleDaily: {
          daysOfTheMonth: [
            {
              date: 1
              isLast: false
            }
          ]
        }
        retentionTimes: scheduleRunTimes
        retentionDuration: {
          count: 60
          durationType: 'Months'
        }
      }
      yearlySchedule: {
        retentionScheduleFormatType: 'Daily'
        monthsOfYear: [
          'January'
          'March'
          'August'
        ]
        retentionScheduleDaily: {
          daysOfTheMonth: [
            {
              date: 1
              isLast: false
            }
          ]
        }
        retentionTimes: scheduleRunTimes
        retentionDuration: {
          count: 10
          durationType: 'Years'
        }
      }
      retentionPolicyType: 'LongTermRetentionPolicy'
    }
    timeZone: 'UTC'
  }
}

var backupFabric = 'Azure'
var protectedItemType = 'Microsoft.ClassicCompute/virtualMachines'
var v2VmContainer = 'iaasvmcontainer;iaasvmcontainerv2;'
var v2Vm = 'vm;iaasvmcontainerv2;'
param existingVirtualMachines array


resource protectedItems 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2021-03-01' = [for item in existingVirtualMachines: {
  name: '${vaultName}/${backupFabric}/${v2VmContainer}${existingVirtualMachinesResourceGroup};${item}/${v2Vm}${existingVirtualMachinesResourceGroup};${item}'
  location: location
  properties: {
    protectedItemType: protectedItemType
    policyId: backupPolicy.id
    sourceResourceId: resourceId(subscription().subscriptionId, existingVirtualMachinesResourceGroup, 'Microsoft.Compute/virtualMachines', item)
  }
  dependsOn: [
    recoveryServicesVault
  ]
}]
