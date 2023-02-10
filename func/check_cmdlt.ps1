function check_cmdlt {
    Write-Host "| "
    Write-Host "| Checking if exsists cmdlt..."
    Write-Host "| "
    $cmdlt_all = (Get-Command).Source
    $cmdlt_list = ".\cmdlt.list"
    $cmdlt = Get-Content $cmdlt_list
    foreach ($line in $cmdlt) {
        $bln = $cmdlt_all.Contains($line)
        if ($bln) {
            # true
            Write-Host "| -- Cmdlt [ ${line} ]  OK --" -ForegroundColor Green
        } else {
            # false
            Write-Host "| -- ERROR -- Module [ ${line} ] not installed." -ForegroundColor Red
            exit
        }
    }
}

