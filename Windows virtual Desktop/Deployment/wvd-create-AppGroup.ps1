#######################################
#    Create New Application Groups    #
#######################################
#   Variablen
$FirstAppGroupName = 'MSAA-WVD'

#   Start
Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com" 
New-RdsAppGroup `
    -TenantName $WVDTenantName `
    -HostPoolName $WVDHostPoolName `
    -Name $FirstAppGroupName `
    -ResourceType RemoteApp `
    -Verbose
Add-RdsAppGroupUser `
    -TenantName $WVDTenantName `
    -HostPoolName $WVDHostPoolName `
    -UserPrincipalName $FQDN `
    -AppGroupName $FirstAppGroupName 