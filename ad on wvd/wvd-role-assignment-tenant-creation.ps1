$tenantAdminUpnOrApplicationId = "" ## MFA is not supported for Tenant Admn
$tenantAdminPassword = ConvertTo-SecureString -String "" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $tenantAdminUpnOrApplicationId, $tenantAdminPassword
$AzureSubscriptionId = "" #Pat should get this for us
$AzureTenantId = "" #Pat should get this for us
$existingTenantName = ""


    ### Importing and Installing modules
    Write-host -foreground Green "Installing and Importing PowerShell Modules"
 
    # Azure Active Directory Module
    if (Get-Module -ListAvailable -Name AzureAD)
    {
         Import-Module AzureAD | Out-Null
    }
    else
    {
         Install-Module -Name AzureAD -scope AllUsers -Confirm:$false -force
         Import-Module AzureAD | Out-Null
    }
     
    # RD Infra Module
    if (Get-Module -ListAvailable -Name Microsoft.RDInfra.RDPowerShell)
    {
         Import-Module Microsoft.RDInfra.RDPowerShell | Out-Null
    }
    else
    {
         Install-Module -Name Microsoft.RDInfra.RDPowerShell -scope AllUsers -Confirm:$false -force
         Import-Module Microsoft.RDInfra.RDPowerShell | Out-Null
    }

# Connect to your Azure AD directory.
Connect-AzureAD -Credential $Credential #Will not need in prod - Vertex will already be authenticated into AzureAD tenant

### After WVD Consent is done, an Enterprise Application called 'Windows Virtual Desktop' will be created - this is the application we will be putting the Admin user into, and then 
### assigning them the role of TenantCreator.

### Assign admin RDS TenantCreator Role
$username = $tenantAdminUpnOrApplicationId
$app_name = "Windows Virtual Desktop"
$app_role_name = "TenantCreator"
 
# Get the user to assign, and the service principal for the app to assign to
$user = Get-AzureADUser -ObjectId "$username"
$sp = Get-AzureADServicePrincipal -Filter "displayName eq '$app_name'" 
$appRole = $sp.AppRoles | Where-Object { $_.DisplayName -eq $app_role_name } 
 
# Assign the user to the app role
New-AzureADUserAppRoleAssignment -ObjectId $user.ObjectId -PrincipalId $user.ObjectId -ResourceId $sp.ObjectId -Id $appRole.Id | out-null
sleep 30
 
### Creating new WVD Tenant
 
# Sign into WVD Environment
Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com" -Credential $Credential -Verbose
sleep 15

# Creating new WVD Tenant
New-RdsTenant -Name $existingTenantName -AadTenantId $AzureTenantId -AzureSubscriptionId $AzureSubscriptionID

