function Confirm_YesNo {
    param($command)
    $title = "| Confirm (y/n)"
    $message = "| Are you sure you want to deploy new Azure resource with this parameter ? "
    $tChoiceDescription = "System.Management.Automation.Host.ChoiceDescription"
    
    $options = @(
        New-Object $tChoiceDescription (" Yes.(&y)","")
        New-Object $tChoiceDescription (" No.(&n)","")
    )
    $result = $host.ui.PromptForChoice($title, $message, $options, 1)
    switch ($result) {
        0 { "|"; . $command; break}
        1 { "|"; "| Canceled."; "|"; break}
    }
}

