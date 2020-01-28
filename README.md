# Automatic Start Stop VM
This repository stores custom azure design patterns.

Design pattern for automatic VM startup and shutdown
Solution overview
Azure Automation is a service in Azure that allows to automate Azure management tasks and to orchestrate actions across external systems from right within Azure. Runbooks in Azure Automation are used to create different tasks. 
In this Pattern we have a runbook called vmstartstop which start and stop the VM based on different criteria’s as mentioned below.
1.	All VM that needs to be managed using this runbook should create a Tag named “startstop” with value as “True”
2.	Start the VM in the morning if this runbook is executed in the Morning.
3.	Don’t’ Start the VM in morning if it is a Holiday. If VM is running stop it.
4.	Stop the VM if this runbook is executed at Night. (Time other than specified in Automation variables as mentioned in point no. 13 in Step 3)
5.	Don’t’ Stop the VM if it is the first day of the month as it is a busy day.
Preparations
Following prerequisites must be met:
•	Create an Automation Account (Follow the following Link for complete process: ) https://docs.microsoft.com/en-us/azure/automation/automation-quickstart-create-account 
•	Create Run-As Account: Follow the process in following link. (https://docs.microsoft.com/en-us/azure/automation/manage-runas-account ):
o	Azure subscription available with Contributor and User Access Administrator roles
o	Azure AD user must have Application Administrator role in Azure AD
•	Browser (Chrome/Firefox, recent version)
•	Create/Update/Download a comma separated HolidayList.txt file store in a public GitHub Repository: https://github.com/singhdigrana/azdesignpatterns (Use mm/dd/yyyy format for dates)
•	By Default runbook runs in UTC Time. For Changing this Behavior Please read “Advance Settings Section at the End of the document. (Go to Advance Settings)

Step 1 – Tag Virtual Machines (Ref. Figure 1)
1.	Create a Tag named “startstop” with value as “True” for all the VM that needs to be managed by this pattern.
2.	Use below comma separated holiday list in (mm\dd\yyyy) format store in github public repo. https://raw.githubusercontent.com/singhdigrana/azdesignpatterns/master/Holidaylist.txt 
 
Figure 1
Step 2 - Import the runbook in Automation Account. (Ref. Figure 2)
3.	Go to Automation Account
4.	Click on Runbook under Process Automation Section
5.	Import a runbook file named “vmstartstop.ps1” from following GitHub Public Repository: https://github.com/singhdigrana/azdesignpatterns.
a.	Name it as vmstartstop.
b.	Select “PowerShell” in “Runbook Type” Dropdown box.
c.	Give a Description of Runbook and Click on Create Button.
 
Figure 2
Step 3 - Create Scheduler for Runbook
Scheduler is used to run the runbook automatically at specified time mentioned in the scheduler. Create a scheduler named “vmstart” to start VM in morning and “vmstop” to stop VM at Night. Follow below steps to link scheduler to runbook.
6.	Click the created “vmstartstop” Runbook for scheduling it to run at specified time. (Check Figure 2 above)
7.	Once inside runbook-Schedules Page, Click on Schedules under Resources Section at left side. (check below figure 3)
8.	Click on “Add a schedule” link in menu bar of the page.

 
Figure 3
9.	Follow the highlighted rectangular boxes in the below figure (Figure 4).
 
Figure 4
10.	Click Create Button and then click Ok Button. You will see vmstart in the scheduler page.
11.	Follow same steps to create another scheduler named “vmstop” to be run at Night. (step 6 to step 10)
12.	Once runbook is scheduled it will automatically start/stop all the VM marked with Tag named startstop with value as “True” in morning and night respectively.
13.	Also, Automation Account is setup with three variables namely “morning_start_time” and “morning_end_time” and timezoneid. These variables specify the time range that will be considered the morning time at the specified time zone in timezoneid variable for the runbook scheduler. If runbook runs between these times in this timezone it will be considered that runbook ran in the morning and all the action for morning will be applied. A file named TimeZoneId.txt file is available at GitHub public account (https://github.com/singhdigrana/azdesignpatterns) for different time zone id’s. Each time zone id can be directly copied and updated in the timezoneid variable.
14.	 See below Figure 5 for the location of these variables. (Automation Account -> Shared Resources -> Variables.


 
Figure 5

Check/Test pattern	
For Testing the Pattern, Observe a running VM with tag startstop=True tag in the Azure portal.
15.	Observe the Current state of the VM scheduled to start/stop
 
Figure 6
16.	Open the Runbook named “vmstartstop” under Automation Account (Automation Account -> Runbooks -> vmstartstop) and click on the start button as shown in below Figure 7.
 
Figure 7
 
17.	Below screen will be displayed. Click on the Output link for log entries. Once VM started/stopped successfully based on the executed scheduler (morning or Night), you will get a respective message in output window!

 
18.	Confirm the status of the VM state in the Azure Virtual Machine Blade as below. You will see Status as “Stopped (deallocated)
 
Advance Settings
•	For changing the time zone do the necessary changes in runbook (vmstartstop.ps1). Decide the Time zone and where this runbook should be running. Based on the time zone decided create the scheduler (as mentioned in Step 3) and also do some changes to the runbook where we are setting a variable named “current_time”. Un-comment the line no. 37, 38 and 39 and comment line no. 36. Follow screenshot in Step-2 for location of the runbook (vmstartstop.ps1) for location of this code.
 

