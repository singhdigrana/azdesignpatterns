<#
    .DESCRIPTION
        Start all the VM's scheduled to start using the Run As Account (Service Principle)
        Before starting the VM, check if today is not holiday in your organisation.

    .NOTES
        AUTHOR: Azure Automation Team
        LASTEDIT: Jan 15, 2019
#>

$connectionName = "AzureRunAsConnection"
try {
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName     
    
    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection) {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    }
    else {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}
$todaysdate = Get-Date -DisplayHint Date
$holidaylist = Get-Content "Holidaylist.txt"
# $holiday = Get-Date -Day 5 -Hour - -Minute 0 -Second 0 -DisplayHint Date
if (!$holidaylist.Contains($todaysdate.ToShortDateString())) {    
    # Get reference to each VM with tag scheduedstart=yes value and start the VM
    $vms = Get-AzureRmResource | Where-Object { $_.ResourceType -eq "Microsoft.Compute/virtualMachines" -and $_.Tags.Values } 
    ForEach ($vm in $vms) {          
        if ($vm.Tags.Name -eq "scheduledstart" -and $vm.Tags.Value -eq "Yes") {
            if ($todaysdate -ne $holiday) {
                Start-AzureRmVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name
                Write-Output ($vm.Name + " Virtual Machine started successfully!") 
            }            
        }        
    }
}
else {
    Write-Host ("Today is Holiday, so Virtual Machine is not started!")
}

