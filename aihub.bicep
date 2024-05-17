
@minLength(4)
@maxLength(18)
param uniqueName string

@description('Location for the cluster.')
param location string = resourceGroup().location

@description('Specifies the Azure Active Directory tenant ID that should be used for authenticating requests to the key vault. Get it by using Get-AzSubscription cmdlet.')
param tenantId string = subscription().tenantId

@description('Array of model deployments for this hub.')
param deployments array


@description('Use UserAssigned Identity for the AI Hub Resource, Always set to false, as it doesnt work')
param userAssignedHub bool = false

// If we havnt passed in an identity to create permissions against, create one
resource hubmi 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = if (userAssignedHub) {
  name: 'hub-${uniqueName}'
  location: location
}
var hubmiId = userAssignedHub ? hubmi.id : ''
var hubmiPrincipalId = userAssignedHub ? hubmi.properties.principalId : ''

//***** AI Hub - Dependencies *****
//-----------------Storage Account Construction-----------------
resource hubstore 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: 'aihubstore${uniqueString(resourceGroup().id)}'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    allowBlobPublicAccess: true
  }

  resource BlobService 'blobServices' = {
    name: 'default'
    properties: {
      cors: {
        corsRules: []
      }
    }

  }
}

@description('This is the built-in Storage Table Data Contributor role.')
resource blobStorageTableContributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3'
}


@description('This is the built-in Storage Account Contributor role.')
resource blobStorageContributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: '17d1049b-9a84-46fb-8f53-869881c3d3ab'
}

@description('This is the built-in Storage Blob Contributor role.')
resource blobStorageDataContributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}

resource roleAssignmentStore 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for roleid in  [
  blobStorageTableContributorRoleDefinition.id
  blobStorageContributorRoleDefinition.id
  blobStorageDataContributorRoleDefinition.id
]: if (userAssignedHub) {
  name: guid(hubstore.id, hubmiId, roleid)
  scope: hubstore
  properties: {
    roleDefinitionId: roleid
    principalId: hubmiPrincipalId
    principalType: 'ServicePrincipal'
  }
}]

resource hubkv 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: 'aihubvault-${uniqueName}'
  location: location
  properties: {
    tenantId: tenantId
    //enableSoftDelete: false
    enableRbacAuthorization: true
    sku: {
      name: 'standard'
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

@description('This is the built-in Key Vault Administrator')
resource keyVaultAdminRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: '00482a5a-887f-4fb3-b363-3b7fe8e74483'
}

@description('This is the built-in Contributor')
resource contributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}


// https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/scenarios-rbac#principal
// The principalId property must be set to a GUID that represents the Microsoft Entra identifier for the principal. In Microsoft Entra ID, this is sometimes referred to as the object ID.
resource roleAssignmentKvUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for roleid in  [
  keyVaultAdminRoleDefinition.id
  contributorRoleDefinition.id
]: if (userAssignedHub) {
  name: guid(hubkv.id, hubmiId, roleid)
  scope: hubkv
  properties: {
    roleDefinitionId: roleid
    principalId: hubmiPrincipalId
    principalType: 'ServicePrincipal'
  }
}]

resource hublogAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: 'aihubloganalytics-${uniqueName}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Disabled'
  }
}

resource hubinsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'aihubinsights-${uniqueName}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    WorkspaceResourceId: hublogAnalytics.id
  }
}

resource roleAssignmentInsights 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (userAssignedHub) {

  name: guid(hubinsights.id, hubmiId , contributorRoleDefinition.id)
  scope: hubinsights
  properties: {
    roleDefinitionId: contributorRoleDefinition.id
    principalId: hubmiPrincipalId
    principalType: 'ServicePrincipal'
  }
}
// ***** AI Hub - Dependencies *****


//---------Azure AI Hub -----------------
// Used to access multiple Azure AI services with a single setup,  single-pain of glass for billing / security & monitoring.
// requries Storage, and KeyVault!
// https://learn.microsoft.com/en-us/azure/templates/microsoft.machinelearningservices/workspaces?pivots=deployment-language-bicep
resource aihub 'Microsoft.MachineLearningServices/workspaces@2024-01-01-preview' = {
  name: 'aihub-${uniqueName}'
  location: location
  kind: 'hub'
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  
  identity: userAssignedHub ? {
      type: 'UserAssigned'
      userAssignedIdentities: {
        '${hubmiId}': {}
      }
    }  : {
      type: 'SystemAssigned'
    }
  
  properties: {
    friendlyName: 'AI Hub created for ${uniqueName}'
    publicNetworkAccess: 'Enabled'
    applicationInsights: hubinsights.id
    storageAccount: hubstore.id
    keyVault: hubkv.id
  }

  // Azure ML workspace connection provides a secure way to store authentication and configuration information needed 
  // to connect and interact with the external resources.

}

output aiHubId string = aihub.id 


@description('Lets you read and list keys of Cognitive Services')
resource CognitiveServicesUserBuiltInRole 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: 'a97b65f3-24c7-4388-baec-2e87135dc908'
}
/*
resource roleAssignmentAIServiceUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (userAssignedHub) {
  name: guid(aiservices.id, hubmiId, CognitiveServicesUserBuiltInRole.id)
  scope: aiservices
  properties: {
    roleDefinitionId: CognitiveServicesUserBuiltInRole.id
    principalId: hubmiPrincipalId
    principalType: 'ServicePrincipal'
  }
}
*/

@description('This is the built-in Storage Blob Contributor role.')
resource cognitiveServicesOpenAIUser 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
}
/*
// https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/role-based-access-control#azure-openai-roles
resource roleAssignmentApp 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(managedIdentityId)) {
  name: guid(aiservices.id, managedIdentityId, cognitiveServicesOpenAIUser.id)
  scope: aiservices
  properties: {
    roleDefinitionId: cognitiveServicesOpenAIUser.id
    principalId: managedIdentityId
    principalType: 'ServicePrincipal'
  }
}

resource roleAssignmentDev 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(localDeveloperId)) {
  name: guid(aiservices.id, localDeveloperId, cognitiveServicesOpenAIUser.id)
  scope: aiservices
  properties: {
    roleDefinitionId: cognitiveServicesOpenAIUser.id
    principalId: localDeveloperId
    principalType: 'User'
  }
}
*/

//--------- Azure AI Services ---------
// Resource used to access multiple Azure AI services with a single setup (provides API endpoints, and common Keys for all services)
// Provides 'Cost Analysis'
// https://learn.microsoft.com/en-us/azure/templates/microsoft.machinelearningservices/workspaces?pivots=deployment-language-bicep
resource aiservices 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = [for d in deployments:{
  name: 'aiser-${uniqueName}-${d.location}'
  location: d.location
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }

  properties: {
    customSubDomainName: 'aiser-${uniqueName}-${d.location}'
    publicNetworkAccess: 'Enabled'
  }


 /* -- Resource has invalid base policy
  resource rai 'raiPolicies' = {
    name: 'default'
    properties: {
      mode: 'Blocking'
      contentFilters: [
        {
          name: 'Hate'
          allowedContentLevel: 'Medium'
          blocking: true
          enabled: true
          source: 'Prompt'
      }
      {
          name: 'Hate'
          allowedContentLevel: 'Medium'
          blocking: true
          enabled: true
          source: 'Completion'
      }
      {
          name: 'Sexual'
          allowedContentLevel: 'Medium'
          blocking: true
          enabled: true
          source: 'Prompt'
      }
      {
          name: 'Sexual'
          allowedContentLevel: 'Medium'
          blocking: true
          enabled: true
          source: 'Completion'
      }
      {
          name: 'Violence'
          allowedContentLevel: 'Medium'
          blocking: true
          enabled: true
          source: 'Prompt'
      }
      {
          name: 'Violence'
          allowedContentLevel: 'Medium'
          blocking: true
          enabled: true
          source: 'Completion'
      }
      {
          name: 'Selfharm'
          allowedContentLevel: 'Medium'
          blocking: true
          enabled: true
          source: 'Prompt'
      }
      {
          name: 'Selfharm'
          allowedContentLevel: 'Medium'
          blocking: true
          enabled: true
          source: 'Completion'
      }
      ]
    }
  }
*/
}]

var models = reduce(deployments, [], (current, next) => concat(array(current), map(next.models, m => union(m, {location: next.location, aiservicesidx: empty(array(current)) ? 0 : last(array(current)).aiservicesidx + 1}))))


@batchSize(1)
resource gpts 'Microsoft.CognitiveServices/accounts/deployments@2023-10-01-preview' = [for (m ,idx) in models: {
  parent:  aiservices[m.aiservicesidx]
  name: '${m.model}-${m.location}'
  properties: {
    model: {
      name: m.model
      format: 'OpenAI'
      version: m.version 
    }
  }
  sku: {
    name: 'Standard'
    capacity: m.quota
  }
}]

@batchSize(1)
resource textembeddingada002 'Microsoft.CognitiveServices/accounts/deployments@2023-10-01-preview'  = [for (d, aiservicesidx) in deployments:{
  parent:  aiservices[aiservicesidx]
  name: 'text-embedding-ada-002-${d.location}'
  properties: {
    model: {
      name: 'text-embedding-ada-002'
      format: 'OpenAI'
    }
  }
  sku: {
    name: 'Standard'
    capacity: 240
  }
  dependsOn: [
    gpts
  ]
}]

resource aiserviceconnection 'Microsoft.MachineLearningServices/workspaces/connections@2024-01-01-preview' = [for (d, aiservicesidx) in deployments:{
  parent: aihub
  name: 'aiservice-${uniqueName}-${d.location}'
  properties: {
    authType: 'ApiKey' // 'ManagedIdentity' //'ApiKey'
    category: 'AIServices'
    isSharedToAll: true
    target: aiservices[aiservicesidx].properties.endpoint
    
    credentials: {
      key: aiservices[aiservicesidx].listKeys().key1
      //clientId: hubmi.properties.clientId
    }

    metadata: {
      ApiType: 'Azure'
      ResourceId: aiservices[aiservicesidx].id
    }
  }
}]

//output openAIEndpoint string = aiservices.properties.endpoints['OpenAI Language Model Instance API']
//output openAIModel string = modelName

/*
//---------OpenAI Construction---------
resource OpenAI 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: openAIName
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: openAIName
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
    publicNetworkAccess: 'Enabled'
  }

  resource gpt 'deployments' = {
    name: modelName
    properties: {
      model: {
        name: modelName
        format: 'OpenAI'
        version: modelVersion 
      }
    }
    sku: {
      name: 'Standard'
      capacity: 120
    }
  }

  resource textembeddingada002 'deployments' = {
    name: 'text-embedding-ada-002'
    properties: {
      model: {
        name: 'text-embedding-ada-002'
        format: 'OpenAI'
      }
    }
    sku: {
      name: 'Standard'
      capacity: 10
    }
    dependsOn: [
      gpt
    ]
  }
}


//---------FormRecognizer Construction---------
resource FormRecognizer 'Microsoft.CognitiveServices/accounts@2023-05-01' = if (false) {
  name: 'aifr-${uniqueName}'
  location: location
  kind: 'FormRecognizer'
  sku: {
    name: 'S0'
  }
  properties: {
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
    publicNetworkAccess: 'Enabled'
  }
}

//---------Translator Construction---------
resource Translator 'Microsoft.CognitiveServices/accounts@2023-05-01' = if (false) {
  name: 'trans-${uniqueName}'
  location: location
  kind: 'TextTranslation'
  sku: {
    name: 'S1'
  }
  properties: {
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
    publicNetworkAccess: 'Enabled'
  }
}

output openAIEndpoint string = OpenAI.properties.endpoint
output openAIModel string = modelName


*/
