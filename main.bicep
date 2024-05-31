targetScope='subscription'

@minLength(4)
@maxLength(18)
param uniqueName string


param teams object


resource hubrg 'Microsoft.Resources/resourceGroups@2022-09-01' =  {
  name: '${uniqueName}-central'
  location: teams.hublocation
}

resource teamrgs 'Microsoft.Resources/resourceGroups@2022-09-01' = [for team in teams.teams:  {
  name: '${uniqueName}-${team}'
  location: teams.hublocation
}]



module aihub 'aihub.bicep' = {
  name: 'deploy-aihub'
  scope: hubrg
  params: {
    uniqueName: uniqueName
    location: teams.hublocation
    deployments: teams.deployments
  }
}

module aiprojects 'aiproject.bicep' = [for (team, teamidx) in teams.teams: {
  name: 'deploy-aiproject-${team}'
  scope: teamrgs[teamidx]
  params: {
    name: 'prj-${uniqueName}-${team}'
    location: teams.hublocation
    aiHubId: aihub.outputs.aiHubId
  }
}]


