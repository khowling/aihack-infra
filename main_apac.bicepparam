using './main.bicep'
// deployments from https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models#standard-deployment-model-availability
param uniqueName = 'ms-hack-am'
param teams = {
    hublocation: 'southindia'
    teams: [
      'team-1'
      'team-2'  
      'team-3'
      'team-4'
      'team-5'
      'team-6'
      'team-7'
      'team-8'
      'team-9'
      'team-10'
      'team-11'
      'team-12'
      'team-13'
      'team-14'
      'team-15'
    ]
    deployments: [
      {
        location: 'southcentralus'
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
        location: 'southindia'
        models: [
          {
            model: 'gpt-4'
            version: '1106-Preview' // "The specified SKU 'Standard' for model 'gpt-4 turbo-2024-04-09' is not supported in this region 'francecentral'
            quota: 150
            sku: 'Standard'
          }
          {
            model: 'gpt-35-turbo'
            version: '1106'
            quota: 300
            sku: 'Standard'
          }
        ]
      }
      {
        location: 'australiaeast'
        models: [
          {
            model: 'gpt-4'
            version: 'vision-preview'
            quota: 30
          }
          {
            model: 'gpt-35-turbo'
            version: '0613'
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
    ]
}
