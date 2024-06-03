using './main.bicep'
// deployments from https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models#standard-deployment-model-availability
param uniqueName = 'ms-hack-am'
param teams = {
    hublocation: 'eastus'
    teams: [
      'team-1'
      'team-2'  
      'team-3'
      'team-5'
      'team-6'
      'team-7'
      'team-8'
    ]
    deployments: [
      {
        location: 'eastus2'
        models: [
          {
            model: 'gpt-4'
            version: 'turbo-2024-04-09' // "The specified SKU 'Standard' for model 'gpt-4 turbo-2024-04-09' is not supported in this region 'francecentral'
            quota: 80
            sku: 'Standard'
          }
          {
            model: 'gpt-35-turbo-16k'
            version: '0613'
            quota: 300
            sku: 'Standard'
          }
        ]
      }
      {
        location: 'eastus'
        models: [
          {
            model: 'dall-e-3'
            version: '3.0'
            quota: 2
            sku: 'Standard'
          }
        ]
      }
      {
        location: 'canadaeast'
        models: [
          {
            model: 'gpt-4'
            version: '1106-Preview'
            quota: 80
            sku: 'Standard'
          }
        ]
      }
      {
        location: 'westus3'
        models: [
          {
            model: 'gpt-4o'
            version: '2024-05-13' 
            quota: 450
            skuName: 'GlobalStandard'
          }   
        ]
      }
    ]
}
