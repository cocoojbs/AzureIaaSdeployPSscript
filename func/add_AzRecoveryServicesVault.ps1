function add_AzRecoveryServicesVault {
    $ErrorActionPreference = "Stop"

    # JSON File Path
    $AzBackupPolicy_parameter_original = $PSScriptRoot + "\json\parameters_bkpol.json"
    $AzBackupPolicy_parameter_edit = $PSScriptRoot + "\json\parameters_edit.json"
    $AzBackupPolicy_template = $PSScriptRoot + "\json\template_bkpol.json"

    foreach ($param in $backup_csv) {
        $vm_name = $param.vmName
        $vm_rg = $param.vmRg
        $rsc_name = $param.RecoveryServicesName
        $rsc_rg = $param.RecoveryServicesRg
        $policy = $param.policyName
        $frequency = $param.scheduleRunFrequency
        $schedule_runtime = $param.scheduleRunTimes
        $instantRp = $param.instantRpRetentionRangeInDays
        $count = $param.count
        $weekly = $param.weeklySchedule
        $timezone = $param.timeZone
        $Redundancy = $param.Redundancy

        if(!($rsc_name)) { break }

        $AzVM = Get-AzVM -Name $vm_name -ResourceGroupName $vm_rg -ErrorAction SilentlyContinue
        if(!($AzVM)) {
            Write-Host -Object "| -- Error -- VM [ ${vm_name} ] not found." -ForegroundColor Red
            break ; Write-Host -Object "|"
        }

        add_ResourceGroup $rsc_rg $location

        $rsc = Get-AzRecoveryServicesVault -Name $rsc_name -ResourceGroupName $rsc_rg -ErrorAction SilentlyContinue
        if(!($rsc)) {
            Write-Host -Object "| -- Azure_Backup [ ${rsc_name} ] --"
            Write-Host -Object "|"
                Write-Host -Object "| RecoveryServicesVault [ ${rsc_name} ] deploying..."
            New-AzRecoveryServicesVault -Name $rsc_name -ResourceGroupName $rsc_rg -Location $AzVM.Location
        }        
        Write-Host -Object "| RSC ResourceID: "
        Write-Host "|"(Get-AzRecoveryServicesVault -Name $rsc_name -ResourceGroupName $rsc_rg).Id
        Write-Host -Object "|"

        # Get-AzRecoveryServicesBackupProtectionPolicy
        Write-Host -Object "| -- Azure_Backup_BackupPolicy [ ${policy} ] in [ ${rsc_name} ] --"
        Write-Host -Object "|"
        $vault = Get-AzRecoveryServicesVault -Name $rsc_name -ResourceGroupName $rsc_rg
        $pol = Get-AzRecoveryServicesBackupProtectionPolicy -Name $policy -VaultId $vault.ID  -ErrorAction SilentlyContinue
        if(!($pol)) {
            Write-Host -Object "| BackupPolicy [ ${policy} ] deploying..."
            # Read parameters.json
            try {
            $Get_BackupPolicy_Config = Get-Content $AzBackupPolicy_parameter_original -Raw | ConvertFrom-Json
            } catch {
                Write-Host -Object "| -- Error -- : " + $Error[0] -ForegroundColor Red
                break
            }

            # Edit parameters
            $UtcTime = Get-Date -Date $schedule_runtime
            $JstTime = $UtcTime.AddHours(+9)
            $Get_BackupPolicy_Config.parameters.timeZone = @{value = $timeZone }
            $Get_BackupPolicy_Config.parameters.vaultName = @{value = $rsc_name }
            $Get_BackupPolicy_Config.parameters.instantRpRetentionRangeInDays = @{value = [int]$instantRp }
            $Get_BackupPolicy_Config.parameters.policyName = @{value = $policy }
            $Get_BackupPolicy_Config.parameters.schedule.value.scheduleRunFrequency = $frequency
            $Get_BackupPolicy_Config.parameters.schedule.value.scheduleRunTimes[0] = $JstTime
            if($frequency -eq "Daily") {
                $Get_BackupPolicy_Config.parameters.schedule.value.scheduleRunDays = $null
                $Get_BackupPolicy_Config.parameters.retention.value.weeklySchedule = $null
                $Get_BackupPolicy_Config.parameters.retention.value.dailySchedule.retentionTimes[0] = $JstTime
                $Get_BackupPolicy_Config.parameters.retention.value.dailySchedule.retentionDuration.count = [int]$count
            } elseif($frequency -eq "Weekly") {
                $Get_BackupPolicy_Config.parameters.retention.value.dailySchedule = $null
                $Get_BackupPolicy_Config.parameters.schedule.value.scheduleRunDays[0] = $weekly
                $Get_BackupPolicy_Config.parameters.retention.value.weeklySchedule.daysOfTheWeek[0] = $weekly
                $Get_BackupPolicy_Config.parameters.retention.value.weeklySchedule.retentionTimes[0] = $JstTime
                $Get_BackupPolicy_Config.parameters.retention.value.weeklySchedule.retentionDuration.count = [int]$count
            } else {
                Write-Host -Object "| -- Error -- Invalid ScheduleRunFrequency. Choose [ Daily ] or [ Weekly ]." -ForegroundColor Red
                break ; Write-Host -Object "|"
            }

            # Rewrite parameters_edit.json
            try {
                $Get_BackupPolicy_Config | ConvertTo-Json -Depth 100 | foreach {
                    [System.Text.RegularExpressions.Regex]::Unescape($_)
                } | Set-Content $AzBackupPolicy_parameter_edit 
            } catch {
                Write-Host -Object "| -- Error -- : " + $Error[0] -ForegroundColor Red
                break ; Write-Host -Object "|"
            }
            try {
                New-AzResourceGroupDeployment -ResourceGroupName $rsc_rg -TemplateFile $AzBackupPolicy_template -TemplateParameterFile $AzBackupPolicy_parameter_edit
                Remove-Item $AzBackupPolicy_parameter_edit
                Write-Host -Object "|"
            } catch {
                Write-Host -Object "| -- Error -- : " + $Error[0] -ForegroundColor Red
                break ; Write-Host -Object "|"
            }
        }

        # Set-AzRecoveryServicesBackupProperty
        $vault = Get-AzRecoveryServicesVault -Name $rsc_name -ResourceGroupName $rsc_rg
        $RSC_Redundancy = Get-AzRecoveryServicesBackupProperties -Vault $vault -ErrorAction SilentlyContinue
        while ($RSC_Redundancy -eq $null) {
            $vault = Get-AzRecoveryServicesVault -Name $rsc_name -ResourceGroupName $rsc_rg
            $RSC_Redundancy = Get-AzRecoveryServicesBackupProperties -Vault $vault -ErrorAction SilentlyContinue
        }
        $Redundancy_type = $RSC_Redundancy.BackupStorageRedundancy
        Write-Host -Object "| Current BackupRedundancy [ ${Redundancy_type} ]"
        Write-Host -Object "|"

        $item = Get-AzRecoveryServicesBackupItem -VaultId $vault.ID -BackupManagementType 'AzureVM' -WorkloadType 'AzureVM'
        if(!($item)) {
            Write-Host -Object "| Changing BackupRedundancy..."
            # Check BackupStorageRedundancy
            if(!($Redundancy -eq $Redundancy_type)) {
                # Set BackupStorageRedundancy
                try{
                    @(1..5) | %{ Set-AzRecoveryServicesBackupProperty -Vault $vault -BackupStorageRedundancy $Redundancy; (START-SLEEP -m 5000); }
                } catch {
                    Write-Host -Object "| -- Error -- : " + $Error[0] -ForegroundColor Red
                    break
                }
                $vault = Get-AzRecoveryServicesVault -Name $rsc_name -ResourceGroupName $rsc_rg
                $Redundancy_type = (Get-AzRecoveryServicesBackupProperties -Vault $vault).BackupStorageRedundancy
                Write-Host -Object "| Current BackupRedundancy [ ${Redundancy_type} ]"
            } else {
                Write-Host -Object "| Changing BackupRedundancy...Skip"
            }
            Write-Host -Object "|"
        }

        # Enable-AzRecoveryServicesBackupProtection
        $pol = Get-AzRecoveryServicesBackupProtectionPolicy -Name $policy -VaultId $vault.ID
        $recoveryVaultInfo = Get-AzRecoveryServicesBackupStatus -Name $AzVM.Name -ResourceGroupName $AzVM.ResourceGroupName -Type 'AzureVM'
        if ($recoveryVaultInfo.BackedUp -eq $true){
            Write-Host -Object "| BackupProtection is already Enabled." -ForegroundColor Yellow
        } else {
            $VmName = $AzVM.Name
            $RscName = $vault.Name
            if($AzVM.Location -eq $vault.Location){
                try {
                    Enable-AzRecoveryServicesBackupProtection -Policy $pol -Name $vm_name -ResourceGroupName $vm_rg -VaultId $vault.ID
                    Write-Host -Object "| Enable-AzRecoveryServicesBackupProtection...Success." -ForegroundColor Green  
                } catch {
                    Write-Host -Object "| -- Error -- : " + $Error[0] -ForegroundColor Red
                    break ; Write-Host -Object "|"
                }
            } else {
                    Write-Host -Object "| -- Error -- VM [ $VmName ] and [ $RscName ] must be in the same location." -ForegroundColor Red
                    break ; Write-Host -Object "|"
            }
        }    
        Write-Host -Object "| VM [ ${vm_name} ] Backup Settings Enabled."
        Write-Host -Object "|"
        Start-Sleep 1
    }
    Write-Host -Object "| function add_AzRecoveryServicesVault complete."
    Write-Host -Object "|"
}

