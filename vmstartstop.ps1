<#
    .DESCRIPTION
        Find all the VM's scheduled to be stopped in all resource groups and start/stop at specified time in scheduler using the Run As Account (Service Principle)

    .NOTES
        AUTHOR: Azure Automation Team
        LASTEDIT: Jan 14, 2019
#>

$connectionName = "AzureRunAsConnection"
try {
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName     
    $vmstatus = "nothing"    

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
$firstDayOfMonth = Get-Date -Day 1 -Hour 0 -Minute 0 -Second 0 -DisplayHint Date
$todaysdate = Get-Date -DisplayHint Date
$holiday = Get-Date -Day 5 -Hour - -Minute 0 -Second 0 -DisplayHint Date
# Get reference to each VM with tag scheduedstop=yes value and stop the VM
$vms = Get-AzureRmResource | Where-Object { $_.ResourceType -eq "Microsoft.Compute/virtualMachines" -and $_.Tags.Values } 
ForEach ($vm in $vms) {          
    if ($vm.Tags.Name -eq "scheduledstop" -and $vm.Tags.Value -eq "Yes") {
        $vmstatus = Get-AzureRmVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status
        ForEach ($vmstatus in $VMStatus.Statuses) {
            $VMStatusDetail = $vmstatus.DisplayStatus
        }        
        if ($VMStatusDetail -eq "VM deallocated") {
            if ($todaysdate -eq $firstDayOfMonth -and $todaysdate -ne $holiday)
            {
                Start-AzureRmVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name
            }
            Start-AzureRmVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name
            Write-Output ($vm.Name + " Virtual Machine started successfully!") 
        }
        else {
            if ($todaysdate -ne $firstDayOfMonth -and $todaysdate -ne $holiday) {
                Stop-AzureRmVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Force  
                Write-Output ($vm.Name + " Virtual Machine stopped successfully!") 
            }
            else
            {
                Write-Output ("Tdoay is first day of the month, so VM can not be stopped");  
            }
        }
        Write-Output ("VM Name: " + $vm.Name), "Status: $VMStatusDetail" `n           
    }        
} 