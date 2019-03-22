Install-Module -Name Microsoft.RDInfra.RDPowerShell

Import-Module -Name Microsoft.RDInfra.RDPowerShell

Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com"

New-RdsTenant -Name Williamtest -AadTenantId 9e2e2052-0f49-4d74-891c-c36095f3af5e -AzureSubscriptionId fed52fef-daba-46ab-8a2c-2843fdbe947c


