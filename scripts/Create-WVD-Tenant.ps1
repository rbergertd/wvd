$SubscriptionId = "fed52fef-daba-46ab-8a2c-2843fdbe947c"
$AzureTenantId = "9e2e2052-0f49-4d74-891c-c36095f3af5e"
$WVDTenantName = "Default Tenant"
$User = "Ryan.berger@tdsolutionfactory.onmicrosoft.com"
$Password = ConvertTo-SecureString -String "Sekur3P@$$Word" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $Password

#Import Module
Import-Module -Name Microsoft.RDInfra.RDPowerShell

Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com" -Credential $Credential

New-RdsTenant -Name TestTenant -AadTenantId $AzureTenantId -AzureSubscriptionId $SubscriptionId


 