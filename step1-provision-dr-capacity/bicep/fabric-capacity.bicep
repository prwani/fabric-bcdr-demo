targetScope = 'resourceGroup'

@description('Name of the Microsoft Fabric capacity. Must start with a lowercase letter and contain only lowercase letters and numbers.')
@minLength(3)
@maxLength(63)
param capacityName string

@description('Azure region for the Fabric capacity.')
param location string = resourceGroup().location

@description('Fabric SKU for the DR capacity.')
@allowed([
  'F2'
  'F4'
  'F8'
  'F16'
  'F32'
  'F64'
  'F128'
  'F256'
  'F512'
  'F1024'
  'F2048'
])
param skuName string = 'F2'

@description('Array of Entra user principal names that will administer the capacity.')
param adminMembers array

@description('Optional resource tags.')
param tags object = {}

resource fabricCapacity 'Microsoft.Fabric/capacities@2023-11-01' = {
  name: capacityName
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: 'Fabric'
  }
  properties: {
    administration: {
      members: adminMembers
    }
  }
}

output capacityId string = fabricCapacity.id
output capacityName string = fabricCapacity.name
output capacityLocation string = fabricCapacity.location
output capacitySku string = fabricCapacity.sku.name
