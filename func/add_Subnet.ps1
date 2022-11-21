function add_Subnet {
    foreach ($line in $nw_csv) {
        $vnetName = $line.vNet_name
        $vnetResourceGroup = $line.vNet_resourceGroup
        $location = $line.location
        $vnetRange = $line.range
        $subnetNames = $line.subnetNames.Split(";")
        $subnetRanges = $line.subnetRanges.Split(";")
        $nsgNames = $line.NSG_names.Split(";")
        $nsgResourceGroups = $line.NSG_resourceGroups.Split(";")

    <#

        add_ResourceGroup $vnetResourceGroup $location
        $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroup $vnetResourceGroup -ErrorAction SilentlyContinue
        if (!($vnet)) {
            Write-Host -Object "| -- Azure_Virtual_Network [ $vnetName ] --"
            Write-Host -Object "|"
            Write-Host -Object "| VNET [ ${vnetName} ] deploying..."
            New-AzVirtualNetwork -Name $vnetName -resourceGroup $vnetResourceGroup -AddressPrefix $vnetRange -Location $location -AsJob -Force | Out-Null
            Get-Job | Wait-Job | Out-Null
            if (Get-Job -State Failed) {
                Write-Host -Object "| -- Error -- some jobs failed as follows:" -ForegroundColor "Red" ; (Get-Job -State Failed).Error
                Get-Job | Remove-Job | Out-Null
                break ; Write-Host -Object "|"
            } else {
                Get-Job | Remove-Job | Out-Null
            }
        }
        Write-Host -Object "| VNET_ID: "
        (Get-AzVirtualNetwork -Name $vnetName -ResourceGroup $vnetResourceGroup).Id
        Write-Host -Object "|"


    #>

        $subnet_num = 0
        foreach ($subnetName in $subnetNames) {
            $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroup $vnetResourceGroup
            $subnet = Get-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet -ErrorAction SilentlyContinue
            if (!($subnet)) {
                Write-Host -Object "| -- Azure_Virtual_Network_Subnet [ $subnetName ] --"
                Write-Host -Object "|"
                Write-Host -Object "| SUBNET [ ${subnetName} ] deploying... "
                $nsg = Get-AzNetworkSecurityGroup -Name $nsgNames[$subnet_num] -resourceGroup $nsgResourceGroups[$subnet_num] -ErrorAction SilentlyContinue
    <#
    
                if (!($nsg)) {
                    add_NSG
                }
                Add-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet `
                -AddressPrefix $subnetRanges[$subnet_num] -NetworkSecurityGroupId $nsg.Id | set-AzVirtualNetwork -AsJob | Out-Null
                Get-Job | Wait-Job | Out-Null
                if (Get-Job -State Failed) {
                        Write-Host -Object "| -- Error -- some jobs failed as follows:" -ForegroundColor "Red" ; (Get-Job -State Failed).Error 
                        Get-Job | Remove-Job | Out-Null
                        break ; Write-Host -Object "|"
                }
    
    #>
            } else {
                break ; Write-Host -Object "|"
            }
            Get-Job | Remove-Job | Out-Null
            Write-Host -Object "| SUBNET ResourceID: "
            $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroup $vnetResourceGroup
            (Get-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet).Id
            Write-Host -Object "|"
            $subnet_num ++ ; Start-Sleep 1
        }
    }
    Write-Host -Object "| function add_Subnet completed."
    Write-Host -Object "|"
}

