param dbName string
@secure()
param adminUserPassword string
param adminUserName string
param serverDomain string
param managedIdentityObjId string
param psqlName string

param location string = resourceGroup().location


resource psqlScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'psqlScript-deployment-script'
  location: location
  kind: 'AzureCLI'
  properties: {
    forceUpdateTag: '1'
    azCliVersion: '2.40.0'
    environmentVariables: [
      {
        name: 'adminUserPassword'
        value: adminUserPassword
      }
      {
        name: 'dbName'
        value: dbName
      }
      {
        name: 'adminUserName'
        value: '${adminUserName}@${psqlName}'
      }
      {
        name: 'serverDomain'
        value: serverDomain
      }
      {
        name: 'managedIdentityObjId'
        value: managedIdentityObjId
      }
    ]
    scriptContent: '''
      adminUserPassword=$(adminUserPassword)
      serverDomain=$(serverDomain)
      adminUserName=$(adminUserName)
      dbName=$(dbName)
      managedIdentityObjId=$(managedIdentityObjId)

      // token get by 'az account get-access-token --resource-type ms-graph --output tsv --query accessToken'

      appId=`curl -XGET "Content-Type: application/json" -H "Authorization: Bearer ${token}" https://graph.microsoft.com/v1.0/servicePrincipals/${managedIdentityObjId} | jq -r .appId`
      
      apk add postgresql-client
      
      cat <<SCRIPT_END > ./initDb.sql
      CREATE ROLE azdmirole WITH LOGIN PASSWORD '$appId' IN ROLE azure_ad_user;
      
      GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "azdmirole";
      SCRIPT_END
      
      psql "host=$serverDomain user=$adminUserName dbname=$dbName port=5432 password=$adminUserPassword sslmode=require" -f ./initDb.sql
    '''
    timeout: 'PT30M'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'PT1H'
  }
}
