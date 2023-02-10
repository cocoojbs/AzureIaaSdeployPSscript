function add_ResourceGroup ($rg_name, $rg_location){
        $resourceGroup = Get-AzResourceGroup -Name $rg_name -ErrorAction SilentlyContinue
        if (!($resourceGroup)) {
            Write-Host -Object "| RESOURCEGROUP [ ${rg_name} ] deploying..."
            New-AzResourceGroup -Name $rg_name -Location $rg_location | Out-Null
            Write-Host -Object "|"
            Write-Host -Object "| RESOURCEGROUP_ID: "
            Write-Host "| "(Get-AzResourceGroup -Name $rg_name).ResourceId
        }
    Write-Host -Object "| - - - - -"
    Write-Host -Object "|"
}

