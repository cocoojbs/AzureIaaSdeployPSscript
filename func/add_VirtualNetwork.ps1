function add_VirtualNetwork {
    foreach ($line in $nw_csv) {
        $vnetName = $line.vNet_name
        $vnetResourceGroup = $line.vNet_resourceGroup
        $location = $line.location
        $vnetRange = $line.range
        $subnetNames = $line.subnetNames.Split(";")
        $subnetRanges = $line.subnetRanges.Split(";")
        $nsgName = $line.NSG_names.Split(";")
        $nsgResourceGroup = $line.NSG_resourceGroups.Split(";")

        Write-Host -Object "| -- Azure_Virtual_Network [ $vnetName ] --"
        Write-Host -Object "|"
        add_ResourceGroup $vnetResourceGroup $location
        $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroup $vnetResourceGroup -ErrorAction SilentlyContinue
        if (!($vnet)) {
            Write-Host -Object "| VNET [ ${vnetName} ] deploying..."
            New-AzVirtualNetwork -Name $vnetName -resourceGroup $vnetResourceGroup -AddressPrefix $vnetRange -Location $location -AsJob -Force | Out-Null
            Get-Job | Wait-Job | Out-Null
            if (Get-Job -State Failed) {
                Write-Host -Object "[ERROR] some jobs failed as follows:" -ForegroundColor "Red" ; (Get-Job -State Failed).Error
                Get-Job | Remove-Job | Out-Null
                break ; Write-Host -Object "|"
            }
            Get-Job | Remove-Job | Out-Null
        }
        Write-Host -Object "| VNET_ID: "
        ($vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroup $vnetResourceGroup).Id
        Write-Host -Object "|"

        #loop
        $nsg_num = 0
        foreach ($subnetName in $subnetNames) {
            if(!($subnetName)){ break }
            $nsg_name = $nsgName[$nsg_num]
            if(!($nsg_name)){ break }
            Write-Host -Object "| -- Azure_Network_Security_Group [ ${nsg_name} ] --"
            Write-Host -Object "|"
            $nsg_rg = $nsgResourceGroup[$nsg_num]
            add_ResourceGroup $nsg_rg $location
            $nsg = Get-AzNetworkSecurityGroup -Name $nsgName[$nsg_num] -resourceGroup $nsg_rg -ErrorAction SilentlyContinue
            if (!($nsg)) {
                Write-Host -Object "| NSG [ ${nsg_name}] ] deploying..."
                New-AzNetworkSecurityGroup -Name $nsgName[$nsg_num] -resourceGroup $nsg_rg -Location $Location -AsJob -Force | Out-Null
                Get-Job | Wait-Job | Out-Null
                if (Get-Job -State Failed) {
                    Write-Host -Object "[ERROR] some jobs failed as follows:" -ForegroundColor "Red" ; (Get-Job -State Failed).Error
                    Get-Job | Remove-Job | Out-Null
                    break ; Write-Host -Object "|"
                }
                Get-Job | Remove-Job | Out-Null
            }
            Write-Host -Object "| NSG_ID: "
            ($nsg = Get-AzNetworkSecurityGroup -Name $nsgName[$nsg_num] -resourceGroup $nsg_rg).Id
            Write-Host -Object "|"

            Write-Host -Object "| -- Azure_Virtual_Network_Subnet [ $subnetName ] --"
            Write-Host -Object "|"
            $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroup $vnetResourceGroup
            $subnet = Get-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet -ErrorAction SilentlyContinue
            if (!($subnet)) {
                Write-Host -Object "| SUBNET [ ${subnetName} ] deploying... "
                $nsg = Get-AzNetworkSecurityGroup -Name $nsgName[$nsg_num] -resourceGroup $nsg_rg
                Add-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet `
                -AddressPrefix $subnetRanges[$nsg_num] -NetworkSecurityGroupId $nsg.Id | set-AzVirtualNetwork -AsJob | Out-Null
                Get-Job | Wait-Job | Out-Null
                if (Get-Job -State Failed) {
                    Write-Host -Object "[ERROR] some jobs failed as follows:" -ForegroundColor "Red" ; (Get-Job -State Failed).Error 
                    Get-Job | Remove-Job | Out-Null
                    break ; Write-Host -Object "|"
                }
                Get-Job | Remove-Job | Out-Null
            }
            Write-Host -Object "| SUBNET ResourceID: "
            $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroup $vnetResourceGroup
            (Get-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet).Id
            Write-Host -Object "|"
            $nsg_num++ ; Start-Sleep 1
        }
        Start-Sleep 1
    }
    Write-Host -Object "| function add_VirtualNetwork completed."
    Write-Host -Object "|"
}

