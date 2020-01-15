<#
    .DESCRIPTION
        Find all the VM's in all resource groups and start/stop at specified time in scheduler using the Run As Account (Service Principle)

    .NOTES
        AUTHOR: Azure Automation Team
        LASTEDIT: Jan 14, 2019
#>

$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName     

    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}
# Get reference to each VM with tag scheduedstop=yes value and stop the VM
$vms = Get-AzureRmResource | Where-Object { $_.ResourceType -eq "Microsoft.Compute/virtualMachines" -and $_.Tags.Values } 
ForEach ($vm in $vms) {          
        if ($vm.Tags.Name -eq "scheduledstop" -and $vm.Tags.Value -eq "Yes")
        {
            Stop-AzureRmVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Force
            Write-Output ($vm.Name + " Virtual Machine stopped successfully!") 
        }        
    } 