function check_cmdlt {
    $cmdlt_all = (Get-Command).Source
    $cmdlt_list = ".\cmdlt.list"
    $cmdlt = Get-Content $cmdlt_list

    foreach ($line in $cmdlt) {
        $bln = $cmdlt_all.Contains($line)
        if ($bln) {
            # true
            Write-Host "| -- check_cmdlt [ ${line} ] passed. --" -ForegroundColor Green
        } else {
            # false
            Write-Host "| -- WARNING --" -ForegroundColor Red
            Write-Host "| Module [ ${line} ] not installed." -ForegroundColor Red
            Write-Host "| Import Azure PowerShell Commandlet Module ." -ForegroundColor Red
            exit
        }
    }
}

