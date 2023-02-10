## Deploy New Virtual Machines from csv parameters
# parameter Files path
$vm_paramFile = ".\csv\vm_parameter.csv"
$nw_paramFile = ".\csv\nw_parameter.csv"
$nsg_paramFile = ".\csv\nsg_parameter.csv"    
$storage_paramFile = ".\csv\storage_parameter.csv"    
$backup_paramFile = ".\csv\backup_parameter.csv"    
$availability_paramFile = ".\csv\availability_parameter.csv"
$list_file = ".\os.list"

# initialize and displya subscription name
Write-Host -Object "|"
Write-Host -Object "| - - - - - - - - - - - - - -"
try {
    $Error.Clear()
    Get-Variable *Obj | Remove-Variable -ErrorAction SilentlyContinue
    (Get-AzSubscription).Name[0] | Out-Null
} catch {
    Write-Host "| -- ERROR -- Get-AzSubscription : Run Connect-AzAccount to login." -ForegroundColor Red
    exit
}

# start of logging
$timeStamp = Get-Date -Format "yyyy-MM-dd_HHmm"
Start-Transcript -Path ".\log\${timeStamp}.log"
Write-Host -Object "| - - - - - - - - - - - - - -"
Write-Host -Object " Subscription:"
(Get-AzContext).Name
Write-Host -Object "|"

# Load Functions
Set-Location -Path (Split-Path -Parent $MyInvocation.MyCommand.Path)
try {
    . .\func\check_Cmdlt.ps1
    . .\func\Confirm_YesNo.ps1
    . .\func\add_ResourceGroup.ps1
    . .\func\add_VirtualNetwork.ps1
    . .\func\add_NSG.ps1
    . .\func\add_Subnet.ps1
    . .\func\add_NetworkInterface.ps1
    . .\func\add_NsgRule.ps1
    . .\func\add_VM.ps1
    . .\func\add_StorageAccount.ps1
    . .\func\add_AzRecoveryServicesVault.ps1
    . .\func\add_AvailabilitySet.ps1
} catch {
    Write-Host "| -- ERROR -- Loading function Files failed." -ForegroundColor Red
    Remove-Variable * -Exclude $rc* -ErrorAction SilentlyContinue
    stop-Transcript
    exit
}

# Function call.Check for the existence of Az modules to be used in the script.
check_Cmdlt

# Load CSVs
try {
    Test-Path -Path $vm_paramFile | Out-Null
    Test-Path -Path $nw_paramFile | Out-Null
    Test-Path -Path $nsg_paramFile | Out-Null
    Test-Path -Path $storage_paramFile | Out-Null
    Test-Path -Path $backup_paramFile | Out-Null
    Test-Path -Path $availability_paramFile | Out-Null
    Test-Path -Path $list_file | Out-Null
} catch {
    Write-Host "| -- ERROR -- Loading parameter Files failed." -ForegroundColor Red
    Remove-Variable * -Exclude $rc* -ErrorAction SilentlyContinue
    stop-Transcript
    exit
}

# MAIN
Write-Host -Object "|"
Write-Host -Object "|"
Write-Host -Object "| - - - - - - - - - - - - - -"
Write-Host -Object "|  VirtualNetwork"
Write-Host -Object "| - - - - - - - - - - - - - -"
$nw_paramFile
$nw_csv = Import-Csv -Path $nw_paramFile
$nw_csv | select-Object vNet_name,vNet_resourceGroup,location,ranges | format-table
Confirm_YesNo add_VirtualNetwork

Write-Host -Object "|"
Write-Host -Object "|"
Write-Host -Object "| - - - - - - - - - - - - - -"
Write-Host -Object "|  NSG"
Write-Host -Object "| - - - - - - - - - - - - - -"
$nw_csv | select-Object NSG_names,NSG_ResourceGroups,subnetNames,vNet_name | format-table
Confirm_YesNo add_NSG

Write-Host -Object "|"
Write-Host -Object "|"
Write-Host -Object "| - - - - - - - - - - - - - -"
Write-Host -Object "|  NsgRule"
Write-Host -Object "| - - - - - - - - - - - - - -"
$nsg_paramFile
$nsg_csv = Import-Csv -Path $nsg_paramFile
$nsg_csv | format-table
Confirm_YesNo add_NsgRule

Write-Host -Object "|"
Write-Host -Object "|"
Write-Host -Object "| - - - - - - - - - - - - - -"
Write-Host -Object "|  Subnet"
Write-Host -Object "| - - - - - - - - - - - - - -"
$nw_csv | select-Object vNet_name,subnetNames,subnetRanges,NSG_names | format-table
Confirm_YesNo add_Subnet

Write-Host -Object "|"
Write-Host -Object "|"
Write-Host -Object "| - - - - - - - - - - - - - -"
Write-Host -Object "|  VM_NIC"
Write-Host -Object "| - - - - - - - - - - - - - -"
$nw_paramFile
$nw_csv | select-Object vm_name,ipAddress,vNet_name,subnetNames | format-table 
Confirm_YesNo add_NetworkInterface

Write-Host -Object "|"
Write-Host -Object "|"
Write-Host -Object "| - - - - - - - - - - - - - -"
Write-Host -Object "|  AvailabilitySet"
Write-Host -Object "| - - - - - - - - - - - - - -"
$availability_paramFile
$availability_csv = Import-Csv -Path $availability_paramFile
$availability_csv | format-table 
Confirm_YesNo add_AvailabilitySet

Write-Host -Object "|"
Write-Host -Object "|"
Write-Host -Object "| - - - - - - - - - - - - - -"
Write-Host -Object "|  VM"
Write-Host -Object "| - - - - - - - - - - - - - -"
$vm_paramFile
$vm_csv = Import-Csv -Path $vm_paramFile
$vm_csv | select-Object vm_name,vm_resourceGroup,vm_size,vmOsDisk_size,ImageName | format-table
Confirm_YesNo add_VM

Write-Host -Object "|"
Write-Host -Object "|"
Write-Host -Object "| - - - - - - - - - - - - - -"
Write-Host -Object "|  StorageAccount"
Write-Host -Object "| - - - - - - - - - - - - - -"
$storage_paramFile
$storage_csv = Import-Csv -Path $storage_paramFile
$storage_csv | select-Object storageName,storageResourceGroup,bootdiag_vmNames,flowlog_nsgs | format-table
Confirm_YesNo add_StorageAccount

Write-Host -Object "|"
Write-Host -Object "|"
Write-Host -Object "| - - - - - - - - - - - - - -"
Write-Host -Object "|  VM_Backup"
Write-Host -Object "| - - - - - - - - - - - - - -"
$backup_paramFile
$backup_csv = Import-Csv -Path $backup_paramFile
$backup_csv | select-Object RecoveryServicesName,RecoveryServicesRg,policyName,scheduleRunFrequency| format-table
Confirm_YesNo add_AzRecoveryServicesVault

Write-Host -Object "|"
Write-Host -Object "| - - - - - - - - - - - - - -"
Write-Host -Object "| deploy_AzVm.ps1 completed. "
Write-Host -Object "| - - - - - - - - - - - - - -"
Write-Host -Object "|"
Remove-Variable * -Exclude $rc* -ErrorAction SilentlyContinue
stop-Transcript
