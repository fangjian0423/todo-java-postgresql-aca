param sqlAdminUser string = 'psqlAdmin'

@secure()
param sqlAdminPassword string
param name string

param location string = resourceGroup().location
param tags object = {}

param keyVaultName string

param databaseName string = 'todo'

param serverEdition string = 'GeneralPurpose'
param skuSizeGB int = 128
param dbInstanceType string = 'Standard_D4ds_v4'
param version string = '12'

module psqlServer '../core/database/postgresql/postgresqlserver.bicep' = {
  name: 'psqlserver'
  params: {
    name: name
    location: location
    tags: tags
    databaseName: databaseName
    keyVaultName: keyVaultName
    serverEdition: serverEdition
    skuSizeGB: skuSizeGB
    dbInstanceType: dbInstanceType
    version: version
    sqlAdminUser: sqlAdminUser
    sqlAdminPassword: sqlAdminPassword
  }
}

output connectionStringKey string = psqlServer.outputs.connectionStringKey
output name string = psqlServer.outputs.name
output databasName string = psqlServer.outputs.databasName
