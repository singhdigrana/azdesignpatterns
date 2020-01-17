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
$uri = "https://raw.githubusercontent.com/singhdigrana/azdesignpatterns/master/Holidaylist.txt"
$webRequest = Invoke-WebRequest -uri $uri -UseBasicParsing

$holidaylist = $webRequest.Content
$holidaylist = $holidaylist.Split(",")
# $dates = $holidaylist | ForEach-Object { [datetime]$_ }
$holiday = $holidaylist | ForEach-Object { [datetime]$_ }
if (!($holiday -contains [datetime]::Today)) {   
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
    Write-Output("Its Holiday! Virtual Machines can not be started!!")
    $vms = Get-AzureRmResource | Where-Object { $_.ResourceType -eq "Microsoft.Compute/virtualMachines" -and $_.Tags.Values } 
    ForEach ($vm in $vms) {      
        Stop-AzureRmVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Force
        Write-Output ($vm.Name + " Virtual Machine stopped successfully!") 
    }
}
$holidaylist = $null;