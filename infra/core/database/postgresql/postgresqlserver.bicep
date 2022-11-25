
param sqlAdminUser string

@secure()
param sqlAdminPassword string

param keyVaultName string
param name string
param databaseName string
param serverEdition string
param skuSizeGB int
param dbInstanceType string
param version string

param location string = resourceGroup().location
param tags object = {}

param connectionStringKey string = 'AZURE-PSQL-CONNECTION-STRING'

resource psqlServer 'Microsoft.DBforPostgreSQL/flexibleServers@2021-06-01' = {
  name: name
  location: location
  tags: union(tags, { 'spring-cloud-azure': true })
  sku: {
    name: dbInstanceType
    tier: serverEdition
  }
  properties: {
    version: version
    administratorLogin: sqlAdminUser
    administratorLoginPassword: sqlAdminPassword
    storage: {
      storageSizeGB: skuSizeGB
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
  }

  resource database 'databases' = {
    name: databaseName
  }

  resource psql_azure_extensions 'configurations' = {
    name: 'azure.extensions'
    properties: {
      value: 'UUID-OSSP'
      source: 'user-override'
    }
  }

  resource firewall 'firewallRules' = {
    name: 'AllowAllWindowsAzureIps'
    properties: {
      startIpAddress: '0.0.0.0'
      endIpAddress: '255.255.255.255'
    }
  }

}


resource psqlConnectionStringKV 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: connectionStringKey
  properties: {
    value: 'jdbc:postgresql://${psqlServer.properties.fullyQualifiedDomainName}:5432/${databaseName}?sslmode=require'
  }
}

resource psqlUserNameKV 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'AZURE-PSQL-USERNAME'
  properties: {
    value: sqlAdminUser
  }
}

resource psqlPasswordKV 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'AZURE-PSQL-PASSWORD'
  properties: {
    value: sqlAdminPassword
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}


output connectionStringKey string = connectionStringKey
output name string = psqlServer.name
output databasName string = databaseName
