@minLength(4)
@maxLength(26)
param name string

@description('Location for the cluster.')
param location string = resourceGroup().location

@description('AI Hub')
param aiHubId string

//--------- Azure AI Project ---------
// Manage assets, permissions, and data settings with projects in Azure Machine Learning
// Inherits Connections to AI Services & a project-specific Blob container from the Hub
resource aiproject 'Microsoft.MachineLearningServices/workspaces@2024-01-01-preview' = {
  name: name
  location: location
  kind: 'project'

  identity: {
    type: 'SystemAssigned'
  }

  properties: {
    hubResourceId: aiHubId
  }

}
