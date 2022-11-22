function add_VirtualNetwork {
    foreach ($line in $nw_csv) {
        $vnetName = $line.vNet_name
        $vnetResourceGroup = $line.vNet_resourceGroup
        $location = $line.location
        $vnetRange = $line.range

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
            }
            Get-Job | Remove-Job | Out-Null
            Write-Host -Object "|"
            Write-Host -Object "| VNET_ID: "
            Write-Host "|"(Get-AzVirtualNetwork -Name $vnetName -ResourceGroup $vnetResourceGroup).Id    
        } else {
            Write-Host -Object "| VNET [ ${vnetName} ] already exists." -ForegroundColor "Yellow"
        }
        Write-Host -Object "|"
    }
    Write-Host -Object "| function add_VirtualNetwork completed."
    Write-Host -Object "|"
}

