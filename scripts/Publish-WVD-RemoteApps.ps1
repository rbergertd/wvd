#Import WVD PS Module
Import-Module -Name Microsoft.RDInfra.RDPowerShell

#Authenticate to Broker (UPN) - log in with AD Tenant admin
Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com"

#Make a new RemoteApp group - "Autocad" in this case
New-RdsAppGroup Tdsolutionfactory td-demo-pool BasicApps -ResourceType "RemoteApp"

#Verify your new RemoteApp group was created
Get-RdsAppGroup Tdsolutionfactory td-demo-pool

#Pull start menu app list - to use AppAlias for easier application publishing
Get-RdsStartMenuApp Tdsolutionfactory td-demo-pool BasicApps

#Publish Apps using AppAlias (autofills in paths, etc)
#ie: New-RdsRemoteApp <TenantName> <PoolName> RemoteAppGrpName -Name "Application Display Name" -AppAlias AppAliasFromAboveCommand

New-RdsRemoteApp Tdsolutionfactory td-demo-pool BasicApps -Name "Inventor 2020" -AppAlias autodeskinventor2020english
New-RdsRemoteApp Tdsolutionfactory td-demo-pool BasicApps -Name "Autocad Mechanical 2020" -AppAlias autocadmechanical2020english
New-RdsRemoteApp Tdsolutionfactory td-demo-pool BasicApps -Name "Word" -AppAlias word
New-RdsRemoteApp Tdsolutionfactory td-demo-pool BasicApps -Name "Published" -AppAlias publisher
New-RdsRemoteApp Tdsolutionfactory td-demo-pool BasicApps -Name "Excel" -AppAlias excel
New-RdsRemoteApp Tdsolutionfactory td-demo-pool BasicApps -Name "PowerPoint" -AppAlias powerpoint
New-RdsRemoteApp Tdsolutionfactory td-demo-pool BasicApps -Name "Notepad" -AppAlias notepad
New-RdsRemoteApp Tdsolutionfactory td-demo-pool BasicApps -Name "Google Chrome" -AppAlias googlechrome
New-RdsRemoteApp Tdsolutionfactory td-demo-pool BasicApps -Name "Adobe Reader" -AppAlias acrobatreaderdc
New-RdsRemoteApp Tdsolutionfactory td-demo-pool BasicApps -Name "Access" -AppAlias access
New-RdsRemoteApp Tdsolutionfactory td-demo-pool BasicApps -Name "Outlook" -AppAlias outlook




#Verify the applications are published
Get-RdsRemoteApp Tdsolutionfactory td-demo-pool BasicApps

#Remove user from desktop group, assign to RemoteApp group - user CANNOT be in both groups at once. You can either see the desktop, or the RemoteApps.
Remove-RdsAppGroupUser Tdsolutionfactory td-demo-pool "Desktop Application Group" -UserPrincipalName demouser@tdsolutionfactory.onmicrosoft.com
Add-RdsAppGroupUser Tdsolutionfactory td-demo-pool BasicApps -UserPrincipalName demouser@tdsolutionfactory.onmicrosoft.com



