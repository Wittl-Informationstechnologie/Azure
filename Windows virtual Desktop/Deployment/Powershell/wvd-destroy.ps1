######################
#    WVD Clean Up    #
######################   
Function Remove-AzureWVD {

    [Cmdletbinding()]
    Param (    
        [Parameter(Mandatory=$true)]
            [string]$WVDTenantName,    
        [Parameter(Mandatory=$true)]
            [string]$WVDHostPoolName
    )
    
    Begin {
        Write-Host `
            -ForegroundColor Magenta `
            -BackgroundColor Black `
            "Preparing to DELETE WVD in 5 Seconds"
        Wait-Event -Timeout 2
        Write-Host -ForegroundColor Red -BackgroundColor Black "5"
        Wait-Event -Timeout 1
        Write-Host -ForegroundColor Red -BackgroundColor Black "4"
        Wait-Event -Timeout 1
        Write-Host -ForegroundColor Red -BackgroundColor Black "3"
        Wait-Event -Timeout 1
        Write-Host -ForegroundColor Red -BackgroundColor Black "2"
        Wait-Event -Timeout 1
        Write-Host -ForegroundColor Red -BackgroundColor Black "1"
        Wait-Event -Timeout 1
        Write-Host -ForegroundColor Red -BackgroundColor Black "Now Removing WVD..."
    }
    
    Process {
        $AppGroup = Get-RdsAppGroup `
            -TenantName $WVDTenantName `
            -HostPoolName $WVDHostPoolName `
            | ? -Property AppGroupName `
                -NE 'Desktop Application Group' `
                -ErrorAction SilentlyContinue
        foreach ($APG in $AppGroup) {        
            Get-RdsRemoteApp `
                -TenantName $WVDTenantName `
                -HostPoolName $WVDHostPoolName `
                -AppGroupName $APG.AppGroupName `
                | Remove-RdsRemoteApp
            Get-RdsAppGroupUser `
                -TenantName $WVDTenantName `
                -HostPoolName $WVDHostPoolName `
                -AppGroupName $APG.AppGroupName `
                | Remove-RdsAppGroupUser        
            $APG | Remove-RdsAppGroup 
            Remove-RdsAppGroup `
                -TenantName $WVDTenantName `
                -HostPoolName $WVDHostPoolName `
                -Name 'Desktop Application Group'
        }     
        Get-RdsSessionHost `
            -TenantName $WVDTenantName `
            -HostPoolName $WVDHostPoolName `
            -ErrorAction SilentlyContinue `
            | Remove-RdsSessionHost
        Get-RdsHostPool `
            -TenantName $WVDTenantName `
            -ErrorAction SilentlyContinue `
            | Remove-RdsHostPool
        Get-RdsTenant `
            -Name $WVDTenantName `
            -ErrorAction SilentlyContinue `
            | Remove-RdsTenant 
    
    }
    
    End {    
        Write-Host "Tenant " -NoNewline; `
        Write-Host $WVDTenantName -ForegroundColor Red -NoNewline; `
        Write-Host " has been removed" -NoNewline;   
       
    }
    
    }
    
    <#
    Remove-AzureWVD `
        -WVDTenantName $WVDTenantName `
        -WVDHostPoolName $WVDHostPoolName `
        -Verbose
    
        #>
    