using './main.bicep'

// deployments from https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models#standard-deployment-model-availability
param uniqueName = 'ms-hack-eu'
param teams = {
    hublocation: 'northeurope'
    teams: [
      'team-1'
      'team-2'  
      'team-3'
      'team-5'
      'team-6'
      'team-7'
      'team-8'
      'team-9'
      'team-10'
      'team-11-12'
      'team-13'
      'team-14'
      'team-15'
      'xuan-99'
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

