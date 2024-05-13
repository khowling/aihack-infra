using './main.bicep'

var EMEAteams = {
    hubname: 'EMEA'
    hublocation: 'northeurope'
    teams: [
      'EMEA-1'
      'EMEA-2'
      'EMEA-3'
      'EMEA-4'
      'EMEA-5'
      'EMEA-6'
      'EMEA-7'
      'EMEA-8'
      'EMEA-9'
    ]
    deployments: [
      {
        location: 'swedencentral'
        models: [
          {
            model: 'gpt-35-turbo-16k'
            version: '0613'
            quota: 300
          }
          {
            model: 'gpt-4'
            version: 'turbo-2024-04-09'
            quota: 150
          }
          {
            model: 'gpt-4'
            version: '1106-Preview'
            quota: 40
          }
          {
            model: 'dall-e-3'
            version: '3.0'
            quota: 2
          }
        ]
      }
      {
        location: 'eastus2'
        models: [
          {
            model: 'gpt-4'
            version: 'turbo-2024-04-09'
            quota: 80
          }
        ]
      }
    ]
  }

param uniqueName = 'khhack01'
param teams = EMEAteams

