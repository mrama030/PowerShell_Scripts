<#
    Author: Mohamed Ali Ramadan
    Date Created: 2018/6/20
    Last Modified By: Mohamed Ali Ramadan
    Last Modified: 2018/6/20
    --------------------------------------------------------------------------------
    Description:
    This script must be scheduled to run every morning on the production server running Archibus v23 on Tomcat.
    The purpose is to refresh the license count to attempt to avoid out of license errors.
    This script can be modified to work with other services, and does not have to specifically be Tomcat. 
    To do so, just modify the variables in the Script Setup section. View step 1, 3 and 4 of the Script Setup section.
#>

#region Script Setup
# ------------------------------------------------------------------------------------------------------

# 1. Define the service name. (Go to Services.msc, right-click on service and click Properties. The "Service name" value should be used.)
$Service_Name = 'Tomcat8' 

#2. Obtain the specified Service.
$Service_Reference = $null

try 
{
    $Service_Reference = Get-Service -Name $Service_Name
}
catch 
{
    Write-Host "The '$Service_Name' service specified was not found. Please correct the Service_Name variable."
}

#3. Specify the folder path of the output log file.
$Log_FolderPath = 'C:\_test'

if ((Test-Path -Path $Log_FolderPath -PathType Container) -eq $false)
{
    Write-Host "The folder path '$Log_FolderPath' specified for the Log_FolderPath variable is invalid."
    exit
}

#4. Specify the filename (LOG file extension by default) of the output log file.
$Log_FileName = 'Tomcat_DailyRestarter_LOG' + '.log'

#endregion

#region Script Functionality
# ------------------------------------------------------------------------------------------------------

$Log_FullFilePath = $Log_FolderPath + '\' + $Log_FileName

$CurrentTime = (Get-Date).ToString()
$Output_Message = "$CurrentTime : The RESTART operation has started..."
Out-File -FilePath $Log_FullFilePath -Append -InputObject $Output_Message

if ($Service_Reference.Status -eq 'Running')
{
    $CurrentTime = (Get-Date).ToString()
    $Output_Message = "$CurrentTime : The '$Service_Name' service WAS RUNNING and will be restarted..." 
    Out-File -FilePath $Log_FullFilePath -Append -InputObject $Output_Message

    $StopService_StartTime = Get-Date

    try 
    {
        Stop-Service -Name $Service_Name -Force
        do
        {
            Start-Sleep -Milliseconds 100
            $Service_Reference = Get-Service -Name $Service_Name
        } until ($Service_Reference.Status -eq 'Stopped')
    }
    catch 
    {
        $CurrentTime = (Get-Date).ToString()
        $Output_Message = "$CurrentTime : ERROR - Unable to Stop the '$Service_Name' service. Restart operation failed." 
        Out-File -FilePath $Log_FullFilePath -Append -InputObject $Output_Message
        Exit
    }

    $StopService_EndTime = Get-Date
    $StopService_TimeDifference = $StopService_EndTime.TimeOfDay.TotalMilliseconds - $StopService_StartTime.TimeOfDay.TotalMilliseconds
    $CurrentTime = (Get-Date).ToString()
    $Output_Message = "$CurrentTime : The '$Service_Name' service was successfully STOPPED in $StopService_TimeDifference ms."
    Out-File -FilePath $Log_FullFilePath -Append -InputObject $Output_Message
}
else 
{
    $CurrentTime = (Get-Date).ToString()
    $Output_Message = "$CurrentTime : CRITICAL WARNING - The '$Service_Name' service WAS STOPPED. Starting the service will be attempted..." 
    Out-File -FilePath $Log_FullFilePath -Append -InputObject $Output_Message
    Write-Host $Output_Message
}

# At this point, the service is in sthe "Stopped" status. It must be started.

$StartService_StartTime = Get-Date

try 
{
    Start-Service -Name $Service_Name
    do
    {
        Start-Sleep -Milliseconds 100
        $Service_Reference = Get-Service -Name $Service_Name
    } until ($Service_Reference.Status -eq 'Running')
}
catch 
{
    $CurrentTime = (Get-Date).ToString()
    $Output_Message = "$CurrentTime : ERROR - Unable to Start the '$Service_Name' service. Restart operation failed." 
    Out-File -FilePath $Log_FullFilePath -Append -InputObject $Output_Message
    Exit
}

$StartService_EndTime = Get-Date
$StartService_TimeDifference = $StartService_EndTime.TimeOfDay.TotalMilliseconds - $StartService_StartTime.TimeOfDay.TotalMilliseconds
$CurrentTime = (Get-Date).ToString()
$Output_Message = "$CurrentTime : The '$Service_Name' service was successfully STARTED in $StartService_TimeDifference ms."
Out-File -FilePath $Log_FullFilePath -Append -InputObject $Output_Message

$NewLine = "`r`n"
$Output_Message = "$CurrentTime : The RESTART operation was succesfully completed." + $NewLine
Out-File -FilePath $Log_FullFilePath -Append -InputObject $Output_Message
Write-Host $Output_Message

#endregion