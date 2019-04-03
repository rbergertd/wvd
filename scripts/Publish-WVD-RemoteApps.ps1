#Import WVD PS Module
Import-Module -Name Microsoft.RDInfra.RDPowerShell

#Authenticate to Broker (UPN) - log in with AD Tenant admin
Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com"

#Make a new RemoteApp group - "Autocad" in this case
New-RdsAppGroup williamtest wvd-pool Autocad -ResourceType "RemoteApp"

#Verify your new RemoteApp group was created
Get-RdsAppGroup williamtest wvd-pool

#Pull start menu app list - to use AppAlias for easier application publishing
Get-RdsStartMenuApp Williamtest wvd-pool Autocad

#Publish Apps using AppAlias (autofills in paths, etc)
#ie: New-RdsRemoteApp <TenantName> <PoolName> RemoteAppGrpName -Name "Application Display Name" -AppAlias AppAliasFromAboveCommand

New-RdsRemoteApp Williamtest wvd-pool Autocad -Name "Inventor 2019" -AppAlias autodeskinventor2019english
New-RdsRemoteApp Williamtest wvd-pool Autocad -Name "Autocad Mechanical 2019" -AppAlias autocad2019englishautocadmechanical
New-RdsRemoteApp Williamtest wvd-pool Autocad -Name "Revit 2019" -AppAlias revit2019

#Verify the applications are published
Get-RdsRemoteApp Williamtest wvd-pool Autocad

#Remove user from desktop group, assign to RemoteApp group - user CANNOT be in both groups at once. You can either see the desktop, or the RemoteApps.
Add-RdsAppGroupUser Williamtest wvd-pool "Desktop Application Group" -UserPrincipalName ryan.berger@thelendingside.com
Add-RdsAppGroupUser Williamtest wvd-pool Autocad -UserPrincipalName ryan.berger@thelendingside.com



