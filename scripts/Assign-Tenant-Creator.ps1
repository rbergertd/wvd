﻿$username = 'adrian@tdsolutionfactory.onmicrosoft.com'
$app_name = "Windows Virtual Desktop"
$app_role_name = "TenantCreator"
 
# Get the user to assign, and the service principal for the app to assign to
$user = Get-AzureADUser -ObjectId "$username"
$sp = Get-AzureADServicePrincipal -Filter "displayName eq '$app_name'" 
$appRole = $sp.AppRoles | Where-Object { $_.DisplayName -eq $app_role_name } 
 
# Assign the user to the app role
New-AzureADUserAppRoleAssignment -ObjectId $user.ObjectId -PrincipalId $user.ObjectId -ResourceId $sp.ObjectId -Id $appRole.Id | out-null
sleep 5
 