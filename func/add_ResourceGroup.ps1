function add_ResourceGroup ($rg_name, $rg_location){
    try {
        $resourceGroup = Get-AzResourceGroup -Name $rg_name -ErrorAction SilentlyContinue
        if (!($resourceGroup)) {
            Write-Host -Object "| RESOURCEGROUP [ ${rg_name} ] deploying..."
            New-AzResourceGroup -Name $rg_name -Location $rg_location | Out-Null
            Write-Host -Object "| RESOURCEGROUP_ID: "
            Write-Host "|"(Get-AzResourceGroup -Name $rg_name).ResourceId
        } else {
            Write-Host -Object "| RESOURCEGROUP [ ${rg_name} ] already exists." -ForegroundColor "Yellow"
        }
    } catch {
        Write-Host "| -- Error -- RESOURCEGROUP [ ${rg_name} ] deploy failed." -ForegroundColor "Red"
    }
    Write-Host -Object "|"
}

