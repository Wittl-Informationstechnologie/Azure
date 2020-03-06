###########################################
#               Variablen                 #
###########################################
$WVDTenantName = 'MSAA-Tenant'
$svcPrincipalFilePath = 'ABFRAGE'

###########################################
#    Install PowerShell Module for WVD    #
###########################################
$Module = 'Microsoft.RDInfra.RDPowerShell'
if((Test-Path -Path "C:\Program Files\WindowsPowerShell\Modules\$Module" -ErrorAction SilentlyContinue)-eq $true) {
        if((Get-Module -Name $Module -ErrorAction SilentlyContinue) -eq $false) {
            Write-Host `
                -ForegroundColor Cyan `
                -BackgroundColor Black `
                "Importing Module"        
            Import-Module -Name $Module -Verbose -ErrorAction SilentlyContinue

        }
        Else {
            Write-Host `
                -ForegroundColor Yellow `
                -BackgroundColor Black `
                "Module already imported"        
        }
    }
else {
        Install-Module -Name $Module -Force -Verbose -ErrorAction Stop    
    }


###########################################
#      Create WvD Service Principal       #
###########################################   
$aadContext = Connect-AzureAD 
$svcPrincipal = New-AzureADApplication -AvailableToOtherTenants $true -DisplayName "Windows Virtual Desktop Svc Principal"
$svcPrincipalCreds = New-AzureADApplicationPasswordCredential -ObjectId $svcPrincipal.ObjectId
 
#Werte in File schreiben
"Password: $svcPrincipalCreds.Value" | Out-File -Append -FilePath $svcPrincipalFilePath
"AAD-TenantID: $aadContext.TenantId.Guid" | Out-File -Append -FilePath $svcPrincipalFilePath
"AppID: $svcPrincipal.AppId" | Out-File -Append -FilePath $svcPrincipalFilePath
 
#Dem Dienstprizipal "RDS-Owner" Rechte geben
Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com" 
Get-RdsTenant
New-RdsRoleAssignment -RoleDefinitionName "RDS Owner" -ApplicationId $svcPrincipal.AppId -TenantName $WVDTenantName
