# AADDS Parameters
$ResourceGroupName = "AutoDeskOnWVD"
$VnetName = "AutoDesk-VNet"
$AzureLocation = "eastus2"
$AzureSubscriptionId = "9b801453-ec47-4e1f-8c70-06ee950eb2ba"
$ManagedDomainName = "tdsolutionfactory.local"

### WVD Parameters
$TenantAdminName = "admin@mynewtenant.onmicrosoft.com" ## MFA is not supported for Tenant Admn
$TenantName = "AutoDesk on WVD" ## New WVD Tenant Name
$TenantAdminPassword = ConvertTo-SecureString -String "Sekur3P@$$Word" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $TenantAdminName, $TenantAdminPassword
$AzureTenantId = "9e2e2052-0f49-4d74-891c-c36095f3af5e"
$AzureADID = "bbbbbbb-bbbbbbb-bbbbbb" ## Azure Active Directory ID, can be found in properties in Azure Active Directory
$rdshNamePrefix = "WVDMachine" ## Prefix of the VDI pool machines that will be created
$rdshNumberOfInstances = "1" ## Number of VM's to be created in the Pool
$rdshVMDiskType = "Premium_LRS" ## Disk type
$rdshVmSize = "Standard_D4s_v3" ## VM size
$domainToJoin = "contoso.com" ## Domain to join the VM's
$existingDomainUPN = "administrator@contoso.com" ## UPN of domain admin
$existingDomainPassword = read-host "Enter domain admin password" -AsSecureString  ## Password of domain admin
$ouPath = "" ## Path to OU where VM will be created. Leave emptye and they will default go in to computer OU
$existingVnetName = "Azure-VNet-01" ## Vnet that is connect to Active Directory
$existingSubnetName = "default" ## Name of the subnate in the VNet
$virtualNetworkResourceGroupName = "Azure-Resource-Group-01" ## Name of resource group where VNet is located"
$existingTenantGroupName = "Default Tenant Group" ## Tenant group name default is Default Tenant Group
$hostPoolName = "NewPool" ## Name of the new host pool 
$defaultDesktopUsers = "user01@contoso.com,user02@contso.com" ## User who get acces to the new WVD desktop 


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
     
    # Azure RM Module
    if (Get-Module -ListAvailable -Name AzureRM)
    {
         Import-Module AzureRM | Out-Null
    }
    else
    {
         Install-Module -Name AzureRM -scope AllUsers -Confirm:$false -force
         Import-Module AzureRM | Out-Null
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
Connect-AzureAD

# Login to your Azure subscription.
Connect-AzAccount

# Create the service principal for Azure AD Domain Services. 
New-AzureADServicePrincipal -AppId "2565bd9d-da50-47d4-8b85-4c97f669dc36"

# Create the delegated administration group for AAD Domain Services.
New-AzureADGroup -DisplayName "AAD DC Administrators" `
    -Description "Delegated group to administer Azure AD Domain Services" `
    -SecurityEnabled $true -MailEnabled $false `
    -MailNickName "AADDCAdministrators"

# First, retrieve the object ID of the newly created 'AAD DC Administrators' group.
$GroupObjectId = Get-AzureADGroup `
    -Filter "DisplayName eq 'AAD DC Administrators'" | `
    Select-Object ObjectId

# Now, retrieve the object ID of the user you'd like to add to the group.
$UserObjectId = Get-AzureADUser `
    -Filter "UserPrincipalName eq '$TenantAdminName'" | `
    Select-Object ObjectId

# Add the user to the 'AAD DC Administrators' group.
Add-AzureADGroupMember -ObjectId $GroupObjectId.ObjectId -RefObjectId $UserObjectId.ObjectId

# Register the resource provider for Azure AD Domain Services with Resource Manager.
Register-AzResourceProvider -ProviderNamespace Microsoft.AAD

# Create the resource group.
New-AzResourceGroup `
    -Name $ResourceGroupName `
    -Location $AzureLocation

# Create the dedicated subnet for AAD Domain Services.
$AaddsSubnet = New-AzVirtualNetworkSubnetConfig `
    -Name DomainServices `
    -AddressPrefix 10.0.0.0/24

$HostPoolSubnet = New-AzVirtualNetworkSubnetConfig `
    -Name Workloads `
    -AddressPrefix 10.0.1.0/24

# Create the virtual network in which you will enable Azure AD Domain Services.
$Vnet = New-AzVirtualNetwork `
    -ResourceGroupName $ResourceGroupName `
    -Location $AzureLocation `
    -Name $VnetName `
    -AddressPrefix 10.0.0.0/16 `
    -Subnet $AaddsSubnet, $HostPoolSubnet

# Enable Azure AD Domain Services for the directory.
New-AzResource -ResourceId "/subscriptions/$AzureSubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.AAD/DomainServices/$ManagedDomainName" `
    -Location $AzureLocation `
    -Properties @{"DomainName" = $ManagedDomainName; `
        "SubnetId"             = "/subscriptions/$AzureSubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Network/virtualNetworks/$VnetName/subnets/DomainServices"
} ` -Force -Verbose

 
### Assign admin RDS TenantCreator Role
$username = $TenantAdminName
$app_name = "Windows Virtual Desktop"
$app_role_name = "TenantCreator"
 
# Get the user to assign, and the service principal for the app to assign to
$user = Get-AzureADUser -ObjectId "$username"
$sp = Get-AzureADServicePrincipal -Filter "displayName eq '$app_name'" 
$appRole = $sp.AppRoles | Where-Object { $_.DisplayName -eq $app_role_name } 
 
# Assign the user to the app role
New-AzureADUserAppRoleAssignment -ObjectId $user.ObjectId -PrincipalId $user.ObjectId -ResourceId $sp.ObjectId -Id $appRole.Id | out-null
sleep 5
 
### Creating new WVD Tenant
 
# Sign into WVD Environment
Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com" -Credential $Credential

# Creating new WVD Tenant
New-RdsTenant -Name $TenantName -AadTenantId $AzureTenantId -AzureSubscriptionId $AzureSubscriptionID
 
### Deploying new host Pool with AzureRM
 
#Sign into Azure
Write-Host -ForegroundColor yellow "Enter your Azure Admin Credentials"
Login-AzureRmAccount
 
# Register RPs
Function RegisterRP {
    Param(
        [string]$ResourceProviderNamespace
    )
 
    Write-Host "Registering resource provider '$ResourceProviderNamespace'";
    Register-AzureRmResourceProvider -ProviderNamespace $ResourceProviderNamespace;
}
 
$resourceProviders = @("microsoft.resources","microsoft.compute");
if($resourceProviders.length) {
    Write-Host -ForegroundColor Green "Registering resource providers"
    foreach($resourceProvider in $resourceProviders) {
        RegisterRP($resourceProvider);
    }
}
 
# Create or check for existing resource group
$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if(!$resourceGroup)
{
    Write-Host -ForegroundColor Green "Creating resource group '$resourceGroupName' in location '$resourceGroupLocation'";
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $AzureLocation
}
else{
    Write-Host -foreground Yellow "Using existing resource group '$resourceGroupName'";
}

# Start the deployment
Write-Host -ForegroundColor Green "Starting Host Pool deployment this can take some time (~15min)..."
$templatefile = "https://raw.githubusercontent.com/Azure/RDS-Templates/master/wvd-templates/Create%20and%20provision%20WVD%20host%20pool/mainTemplate.json"
New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name "New-WVD-HostPool" -TemplateUri $templatefile `
-tenantAdminPassword $tenantAdminPassword `
-rdshNamePrefix $rdshNamePrefix `
-rdshNumberOfInstances $rdshNumberOfInstances `
-rdshVMDiskType $rdshVMDiskType `
-rdshVmSize $rdshVmSize `
-domainToJoin $domainToJoin `
-existingDomainUPN $existingDomainUPN `
-existingDomainPassword $existingDomainPassword `
-ouPath $ouPath `
-existingVnetName $existingVnetName `
-existingSubnetName $existingSubnetName `
-virtualNetworkResourceGroupName $virtualNetworkResourceGroupName `
-existingTenantGroupName $existingTenantGroupName `
-hostPoolName $hostPoolName `
-defaultDesktopUsers $defaultDesktopUsers `
-rdshImageSource $rdshImageSource `
-vmImageVhdUri $vmImageVhdUri `
-rdshGalleryImageSKU $rdshGalleryImageSKU `
-rdshCustomImageSourceName $rdshCustomImageSourceName `
-rdshCustomImageSourceResourceGroup $rdshCustomImageSourceResourceGroup `
-enableAcceleratedNetworking $enableAcceleratedNetworking `
-rdshUseManagedDisks $rdshUseManagedDisks `
-storageAccountResourceGroupName $storageAccountResourceGroupName `
-newOrExistingVnet $newOrExistingVnet `
-existingTenantName $existingTenantName `
-enablePersistentDesktop $enablePersistentDesktop `
-tenantAdminUpnOrApplicationId $tenantAdminUpnOrApplicationId `
-isServicePrincipal $isServicePrincipal `
-location $location
### Checking Host Pool
$hostPool = Get-RdsHostPool -TenantName $tenantName -Name $HostPoolName
if(!$hostpool){
 write-host -ForegroundColor red "Something went wrong check te deployment in the resource group"
}else{
 write-host -ForegroundColor green "WVD Tenant is created and users can now sign in to https://rdweb.wvd.microsoft.com/webclient/index.html"
}