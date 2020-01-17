<#
    .DESCRIPTION
        Start/Stop all the VM's scheduled to start using the Run As Account (Service Principle)
        Before Starting the VM, check if today is not holiday in your organisation. if holiday and vm is running stop it.
        Before Stopping the VM, Check if its not the first day of the Month, As first day of month is a busy day!

    .NOTES
        AUTHOR: Azure Automation Team
        LASTEDIT: Jan 17, 2019
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
$morning_start_time = Get-AutomationVariable -Name 'morning_start_time'
$morning_end_time = Get-AutomationVariable -Name 'morning_end_time'

#By Default it is taking UK time
Write-Output(Get-Date)
# Start the VM
if ($current_time -ge $morning_start_time -and $current_time -le $morning_end_time) {        
    Write-Output("Its Morning - start the virtual machine")
    $uri = "https://raw.githubusercontent.com/singhdigrana/azdesignpatterns/master/Holidaylist.txt"
    $webRequest = Invoke-WebRequest -uri $uri -UseBasicParsing

    $holidaylist = $webRequest.Content
    $holidaylist = $holidaylist.Split(",")    
    $holiday = $holidaylist | ForEach-Object { [datetime]$_ }
    if (!($holiday -contains [datetime]::Today)) {   
        $vms = Get-AzureRmResource | Where-Object { $_.ResourceType -eq "Microsoft.Compute/virtualMachines" -and $_.Tags.Values } 
        ForEach ($vm in $vms) {          
            if ($vm.Tags.Name -eq "startstop" -and $vm.Tags.Value -eq "True") {
                if ($todaysdate -ne $holiday) {
                    Start-AzureRmVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name
                    Write-Output ($vm.Name + " : Virtual Machine started successfully!") 
                }            
            }        
        }
    }
    else {
        Write-Output("Its Holiday! Virtual Machines can not be started!!")
        $vms = Get-AzureRmResource | Where-Object { $_.ResourceType -eq "Microsoft.Compute/virtualMachines" -and $_.Tags.Values } 
        ForEach ($vm in $vms) {          
            if ($vm.Tags.Name -eq "startstop" -and $vm.Tags.Value -eq "True") {
                Stop-AzureRmVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Force
            }        
        }
    }
    $holidaylist = $null;
}
else {
    #Stop the Machine
    Write-Output("Its Night - Stop the virtual machine");    
    $vms = Get-AzureRmResource | Where-Object { $_.ResourceType -eq "Microsoft.Compute/virtualMachines" -and $_.Tags.Values } 
    ForEach ($vm in $vms) {          
        if ($vm.Tags.Name -eq "startstop" -and $vm.Tags.Value -eq "True") {
            if ($todaysdate -ne $firstDayOfMonth) {
                Stop-AzureRmVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Force
                Write-Output ($vm.Name + " : Virtual Machine stopped successfully!")                 
            }
        }        
    }
}