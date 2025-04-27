var location = resourceGroup().location

var storageAccountName = 'stcabavsinternals'
var storageShareName = 'fs-jenkinshome'
var acaEnvironmentName = 'cae-cabavsinternals'
var containerAppName = 'aca-jenkins'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

resource fileService 'Microsoft.Storage/storageAccounts/fileServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
}

resource storageShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = {
  parent: fileService
  name: storageShareName
  properties: {
    accessTier: 'TransactionOptimized'
  }
}

resource acaEnv 'Microsoft.App/managedEnvironments@2023-11-02-preview' = {
  name: acaEnvironmentName
  location: location
  properties: {
    daprAIInstrumentationKey: ''
  }
}

resource acaEnvStorage 'Microsoft.App/managedEnvironments/storages@2023-11-02-preview' = {
  parent: acaEnv
  name: 'default'
  properties: {
    azureFile: {
      accountName: storageAccount.name
      accountKey: storageAccount.listKeys().keys[0].value
      shareName: storageShare.name
      accessMode: 'ReadWrite'
    }
  }
}

resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: acaEnv.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
        transport: 'auto'
        allowInsecure: false
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
      activeRevisionsMode: 'Single'
    }
    template: {
      containers: [
        {
          name: 'jenkins'
          image: 'jenkins/jenkins:2.426.3-lts'
          resources: {
            cpu: 1
            memory: '2Gi'
          }
          volumeMounts: [
            {
              volumeName: storageShare.name
              mountPath: '/var/jenkins_home'
            }
          ]
        }
      ]
      volumes: [
        {
          name: storageShare.name
          storageType: 'AzureFile'
          storageName: 'default'
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}

output storageAccountName string = storageAccount.name
output containerAppUrl string = 'https://${containerApp.name}.${location}.azurecontainerapps.io'
