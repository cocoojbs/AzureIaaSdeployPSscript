function add_NSG {
    foreach ($line in $nw_csv) {
        $location = $line.location
        $nsgNames = $line.NSG_names.Split(";")
        $nsgResourceGroup = $line.NSG_resourceGroups.Split(";")

Write-Host -Object "| -- Azure_Network_Security_Group [ ${nsg_name} ] --"
Write-Host -Object "|"
$nsg_num = 0
foreach ($nsgName in $nsgNames) {
    if(!($nsgName)){ break }
    $nsg_rg = $nsgResourceGroup[$nsg_num]
    add_ResourceGroup $nsg_rg $location
    $nsg = Get-AzNetworkSecurityGroup -Name $nsgName -resourceGroup $nsg_rg -ErrorAction SilentlyContinue
    if (!($nsg)) {
        Write-Host -Object "| NSG [ ${nsgName}] ] deploying..."
        New-AzNetworkSecurityGroup -Name $nsgName -resourceGroup $nsg_rg -Location $Location -AsJob -Force | Out-Null
        Get-Job | Wait-Job | Out-Null
        if (Get-Job -State Failed) {
            Write-Host -Object "[ERROR] some jobs failed as follows:" -ForegroundColor "Red" ; (Get-Job -State Failed).Error
            Get-Job | Remove-Job | Out-Null
            break ; Write-Host -Object "|"
        }
        Get-Job | Remove-Job | Out-Null
    }
    Write-Host -Object "| NSG_ID: "
    ($nsg = Get-AzNetworkSecurityGroup -Name $nsgName -resourceGroup $nsg_rg).Id
    Write-Host -Object "|"

    Write-Host -Object "| function add_NSG completed."
    Write-Host -Object "|"
}

