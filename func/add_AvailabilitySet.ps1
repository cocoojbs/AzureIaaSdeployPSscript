function add_AvailabilitySet {
    foreach ($line in $availability_csv) {
        $asetName = $line.AvailabilitySet
        $rgName = $line.vm_resourceGroup
        $location = $line.Location
        $updateDomain = $line.UpdateDomain
        $faultDomain = $line.FaultDomain
        $ppgName = $line.ProximityPlacementGroup

        add_ResourceGroup $rgName $location

        # Check if VM_RESOURCEGROUP exists.
        if ($ppgName) {
            $ppg = Get-AzProximityPlacementGroup -Name $ppgName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
            if (!($ppg)) {
                Write-Host -Object "| -- Proximity_Placement_Group [ $ppgName ] --"
                Write-Host -Object "|"
                        Write-Host -Object "| ProximityPlacementGroup [ ${ppgName} ] deploying..."
                New-AzProximityPlacementGroup -Name $ppgName -ResourceGroupName $rgName -Location $location -AsJob | Out-Null
                Get-Job | Wait-Job | Out-Null
                if (Get-Job -State Failed) {
                    Write-Host -Object "| -- Error -- some jobs failed as follows:" -ForegroundColor "Red" ; (Get-Job -State Failed).Error
                    Get-Job | Remove-Job | Out-Null
                    break ; Write-Host -Object "|"
                }
                Get-Job | Remove-Job | Out-Null
            }
            Write-Host -Object "| ProximityPlacementGroup ResourceID: "
            (Get-AzProximityPlacementGroup -Name $ppgName -ResourceGroupName $rgName).Id
            Write-Host -Object "|"
        }

        Write-Host -Object "| -- Availability_Set [ $asetName ] --"
        Write-Host -Object "|"
        $aset = Get-AzAvailabilitySet -Name $asetName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
        if (!($aset)) {
            Write-Host -Object "| AvailabilitySet [ ${asetName} ] deploying..."
            if ($ppgName) {
                $ppg=get-AzProximityPlacementGroup -Name $ppgName -ResourceGroupName $rgName
                New-AzAvailabilitySet -Name $asetName -ResourceGroupName $rgName -Location $location -Sku aligned `
                -PlatformUpdateDomainCount $updateDomain -PlatformFaultDomainCount $faultDomain -ProximityPlacementGroupId $ppg.Id -AsJob | Out-Null
            } else {
                New-AzAvailabilitySet -Name $asetName -ResourceGroupName $rgName -Location $location -Sku aligned `
                -PlatformUpdateDomainCount $updateDomain -PlatformFaultDomainCount $faultDomain -AsJob | Out-Null
            }
            Get-Job | Wait-Job | Out-Null
            if (Get-Job -State Failed) {
                Write-Host -Object "| -- Error -- some jobs failed as follows:" -ForegroundColor "Red" ; (Get-Job -State Failed).Error
                Get-Job | Remove-Job | Out-Null
                break ; Write-Host -Object "|"
            }
            Get-Job | Remove-Job | Out-Null
        }
        Write-Host -Object "| AvailabilitySet ResourceID: "
        Write-Host "|"($aset = Get-AzAvailabilitySet -Name $asetName -ResourceGroupName $rgName).Id
        Write-Host -Object "|"
        Start-Sleep 1
    }
    Write-Host -Object "| function add_AvailabilitySet completed."
    Write-Host -Object "|"
}

