<#
    .DESCRIPTION
        Start/Stop all the VM's scheduled to start using the Run As Account (Service Principle)
        Before Starting the VM, check if today is not holiday in your organisation.
        Before Stopping the VM, Check if its not the first day of the Month, As first day of month is a busy day!

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
$firstDayOfMonth = Get-Date -Day 1 -Hour 0 -Minute 0 -Second 0 -DisplayHint Date

$current_time = Get-Date -DisplayHint Time
$morningStartTime = "9:00"
$morningEndTime = "11:55"

if ($current_time -ge $morningStartTime -and $current_time -le $morningEndTime) {
    Write-Host("Its Morning-start the machine");
    # $holidaylist = Get-Content "Holidaylist.txt"
    $holidaylist = '6/10/2017', '6/11/2017', '1/16/2020'
    $dates = $holidaylist | ForEach-Object { [datetime]$_ }
    if (!($dates -contains [datetime]::Today)) {
        Write-Host("No Holiday!")
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
        Write-Host("Today is Holiday, so Virtual Machine is not started!!")
    }
}
else {
    #Stop the Machine
    Write-Host("Its Evening - stop the machine");    
    # Get reference to each VM with tag scheduedstop=yes value and stop the VM
    $vms = Get-AzureRmResource | Where-Object { $_.ResourceType -eq "Microsoft.Compute/virtualMachines" -and $_.Tags.Values } 
    ForEach ($vm in $vms) {          
        if ($vm.Tags.Name -eq "scheduledstop" -and $vm.Tags.Value -eq "Yes") {
            if ($todaysdate -ne $firstDayOfMonth) {
                Stop-AzureRmVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Force
                Write-Output ($vm.Name + " Virtual Machine stopped successfully!") 
            }
        }        
    }
}