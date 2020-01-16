<#
    .DESCRIPTION
        Stop all the VM's scheduled to stop using the Run As Account (Service Principle)
        Before Stoping the VM, Check if this is not the first day of month which is usually a busy day Organisation.
    
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
$firstDayOfMonth = Get-Date -Day 1 -Hour 0 -Minute 0 -Second 0 -DisplayHint Date
$todaysdate = Get-Date -DisplayHint Date
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