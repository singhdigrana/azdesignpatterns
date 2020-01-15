<#
    .DESCRIPTION
        Find all the VM's in DS-DesignPatterns resource group and stop at specified time in scheduler using the Run As Account (Service Principle)

    .NOTES
        AUTHOR: Azure Automation Team (Digamber Singh)
        LASTEDIT: Jan 10, 2019
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
        if ($vm.Tags.Name -eq "scheduledstart" -and $vm.Tags.Value -eq "Yes")
        {
            Start-AzureRmVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name
            Write-Output ($vm.Name + " Virtual Machine started successfully!") 
        }        
    } 