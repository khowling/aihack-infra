using './main.bicep'

// deployments from https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models#standard-deployment-model-availability
param uniqueName = 'ms-back-eu'
param teams = {
    hublocation: 'northeurope'
    teams: [
      'backup-1'
      'backup-2'  
      'backup-3'
      'backup-4'
      'backup-5'
    ]
    deployments: [
      {
        location: 'eastus2'
        embeddingsQuota: 110
        models: [
          {
            model: 'gpt-4o'
            version: '2024-05-13' 
            quota: 450
            skuName: 'GlobalStandard'
          }
        ]
      }
      {
        location: 'francecentral'
        models: [
          {
            model: 'gpt-4'
            version: '1106-Preview' // "The specified SKU 'Standard' for model 'gpt-4 turbo-2024-04-09' is not supported in this region 'francecentral'
            quota: 80
          }
          {
            model: 'gpt-35-turbo'
            version: '0613'
            quota: 240
          }
        ]
      }
      {
        location: 'swedencentral'
        models: [
          {
            model: 'gpt-4'
            version: 'turbo-2024-04-09'
            quota: 150
          }
          {
            model: 'gpt-35-turbo'
            version: '1106'
            quota: 300
          }
          {
            model: 'dall-e-3'
            version: '3.0'
            quota: 2
          }
          {
            model: 'davinci-002'
            version: '1'
            quota: 240
          }
        ]
      }
      {
        location: 'westeurope'
        models: [
          {
            model: 'gpt-35-turbo'
            version: '0301'
            quota: 240
          }
        ]
      }
    ]
  }

