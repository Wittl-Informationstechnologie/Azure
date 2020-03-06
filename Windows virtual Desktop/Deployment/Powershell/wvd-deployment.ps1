#   Variablen
$AADTenantID = Read-Host -Prompt "Azure AD Tenant-ID"
$SubscriptionID = Read-Host -Prompt "Azure Subscription-ID"
$WVDTenantName = Read-Host -Prompt "WVD-Tenant Name"
$WVDHostPoolName = Read-Host -Prompt "WVD-Hostpool Name"

Read-Host "Konfiguration WVD-VM. Eingabe zum Fortführen"

$ResourceGroup = Read-Host -Prompt "bestehende ResourceGroup in die der WVD deployed werden soll"
$Vnet = Read-Host -Prompt "bestehendes Vnet in das der WVD deployed werden soll"
$Subnet = Read-Host -Prompt "bestehendes Subnet aus $Vnet , in das der WVD deployed werden soll"
$WvdVmName = Read-Host -Prompt "Virtual Machine Prefix"
$WvdInstanzen = Read-Host -Prompt "Anzahl der WVD Instanzen (VMs)"
$AadDsDomain = Read-Host -Prompt "Azure AD DomainService Domain (Domain.tld)"
Read-Host "Global Admin zum erstellen von Ressourcen (Global Admin) Beliebige Taste zum Öffnen der Eingabe!"
$AdminUser = Get-Credential
Read-Host "wvdjoiner@domain.tld (wichtig für WVD) Beliebige Taste zum Öffnen der Eingabe!"
$wvdjoiner = Get-Credential
$svcPrincipalFilePath = Read-Host -Prompt "Pfad für Passwortfile des Service Prinzipals (Pfad bis Zielordner)"


#   Install PowerShell Modules

#   WVD-Modul installieren
$ModuleWVD = 'Microsoft.RDInfra.RDPowerShell'
if((Test-Path -Path "C:\Program Files\WindowsPowerShell\Modules\$ModuleWVD" -ErrorAction SilentlyContinue)-eq $true) {
        if((Get-Module -Name $ModuleWVD -ErrorAction SilentlyContinue) -eq $false) {
            Write-Host `
                -ForegroundColor Cyan `
                -BackgroundColor Black `
                "Importing Module"        
            Import-Module -Name $ModuleWVD -Verbose -ErrorAction SilentlyContinue

        }
        Else {
            Write-Host `
                -ForegroundColor Yellow `
                -BackgroundColor Black `
                "Module already imported"        
        }
    }
else {
        Install-Module -Name $ModuleWVD -Force -Verbose -ErrorAction Stop    
    }

#   AzureAD-Modul installieren
$ModuleAzureAD = 'AzureAD'
if((Test-Path -Path "C:\Program Files\WindowsPowerShell\Modules\$ModuleAzureAD" -ErrorAction SilentlyContinue)-eq $true) {
       if((Get-Module -Name $ModuleAzureAD -ErrorAction SilentlyContinue) -eq $false) {
            Write-Host `
                -ForegroundColor Cyan `
                -BackgroundColor Black `
                "Importing Module"        
            Import-Module -Name $ModuleAzureAD -Verbose -ErrorAction SilentlyContinue

        }
        Else {
            Write-Host `
                -ForegroundColor Yellow `
                -BackgroundColor Black `
                "Module already imported"        
        }
    }
else {
         Install-Module -Name $ModuleAzureAD -Force -Verbose -ErrorAction Stop    
    }


#   create wvdjoiner
$wvdjoinerPasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$wvdjoinerPasswordProfile.Password = $wvdjoiner.Password

New-AzureADUser 
    -DisplayName $wvdjoiner.UserName `
    -PasswordProfile $wvdjoinerPasswordProfile `
    -UserPrincipalName $wvdjoiner.UserName `
    -AccountEnabled $true

#   deploy Azure AD Service
New-AzResourceGroupDeployment `
    -ResourceGroupName $ResourceGroup `
    -TemplateFile "C:\Users\MaximilianBayer\OneDrive - Wittl-IT\Dokumente\Azure\Windows Virtual Desktop\.json\AadServicetemplateAusAzure.json" `
    -TemplateParameterFile "C:\Users\MaximilianBayer\OneDrive - Wittl-IT\Dokumente\Azure\Windows Virtual Desktop\.json\DeploymentParameters.json" `

Start-Sleep -Seconds 3600


#   wvdjoiner to Domainadmins Group
$AdminGroup = Get-AzureADGroup -SearchString "AAD DC Administrators"
$AdminGroupID = $AdminGroup.ObjectId

Add-AzureADGroupMember `
    -ObjectId $AdminGroupID `
    -RefObjectId $wvdjoiner.UserName


#   Verknüpfen Azure Tenant mit RDS Broker 
Start-Process https://rdweb.wvd.microsoft.com 
Start-Process https://rdweb.wvd.microsoft.com
$AADTenantID

Read-Host "Eingabe zum Fortführen"

Start-Sleep -Seconds 120

#   WVD TenantCreator setzen
$RDSTenant_Creator = $wvdjoiner.UserName
$RDSapp_name = "Windows Virtual Desktop"
$RDSapp_role_name = "TenantCreator"
$aadContext = Connect-AzureAD
$RDSuser = Get-AzureADUser -ObjectId "$RDSTenant_Creator"
$RDSsp = Get-AzureADServicePrincipal -Filter "displayName eq '$RDSapp_name'"
$RDSappRole = $RDSsp.AppRoles | Where-Object { $_.DisplayName -eq $RDSapp_role_name }
New-AzureADUserAppRoleAssignment -ObjectId $RDSuser.ObjectId -PrincipalId $RDSuser.ObjectId -ResourceId $RDSsp.ObjectId -Id $RDSappRole.Id

Start-Sleep -Seconds 1800


#   Create WvD Service Principal
  
$svcPrincipal = New-AzureADApplication -AvailableToOtherTenants $true -DisplayName "Windows Virtual Desktop Svc Principal"
$svcPrincipalCreds = New-AzureADApplicationPasswordCredential -ObjectId $svcPrincipal.ObjectId
 
#   svc Daten in File schreiben
$date = Get-Date -Format "dd/MM/yyyy_HH.mm.ss"
"Password: $svcPrincipalCreds.Value" | Out-File -Append -FilePath $svcPrincipalFilePath\Principal_$WVDTenantName_$date.txt
"AAD-TenantID: $aadContext.TenantId.Guid" | Out-File -Append -FilePath $svcPrincipalFilePath\Principal_$WVDTenantName_$date.txt
"AppID: $svcPrincipal.AppId" | Out-File -Append -FilePath $svcPrincipalFilePath\Principal_$WVDTenantName_$date.txt
 
#svc Pass convert to secure
$svcPass = ConvertTo-SecureString  $svcPrincipalCreds.Value -AsPlainText -Force


#   Create New WVD Tenant
Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com" 
New-RDSTenant `
    -Name $WVDTenantName `
    -AadTenantId $AADTenantID `
    -AzureSubscriptionId $SubscriptionID 
New-RdsHostPool `
    -TenantName $WVDTenantName `
    -Name $WVDHostPoolName `
    -FriendlyName $WVDHostPoolName
#   Dem Dienstprizipal "RDS-Owner" Rechte geben
New-RdsRoleAssignment -RoleDefinitionName "RDS Owner" -ApplicationId $svcPrincipal.AppId -TenantName $WVDTenantName


#   WVD VM Deploy
<#
$WvdVmParameter = @{ 
        '_artifactsLocation' = 'https://raw.githubusercontent.com/Azure/RDS-Templates/master/wvd-templates/'
        'rdshNamePrefix' = $WvdVmName
        'rdshNumberOfInstances' = $WvdInstanzen
        'domainToJoin' = $AadDsDomain
        'existingDomainUPN' = $AdminUser.Username
        'existingDomainPassword' = $AdminUser.Password
        'existingVnetName' = $Vnet
        'existingSubnetName' = $Subnet
        'virtualNetworkResourceGroupName' = $ResourceGroup
        'existingTenantName' = $WVDTenantName
        'hostPoolName' = $WVDHostPoolName
        'tenantAdminUpnOrApplicationId' = $svcPrincipal.AppId
        'tenantAdminPassword' = $svcPass
        'aadTenantId' = $aadContext.TenantId.Guid
}
#>
New-AzResourceGroupDeployment `
    -ResourceGroupName $ResourceGroup `
    -TemplateFile "C:\Users\MaximilianBayer\OneDrive - Wittl-IT\Dokumente\Azure\Windows Virtual Desktop\.json\WVDTemplate.json" `
    -TemplateParameterFile "C:\Users\MaximilianBayer\OneDrive - Wittl-IT\Dokumente\Azure\Windows Virtual Desktop\.json\DeploymentParameters.json" `
    #-TemplateParameterObject $WvdVmParameter



# delete default Desktop AppGroup

Remove-RdsAppGroup $WVDTenantName $WVDHostPoolName "Desktop Application Group"

