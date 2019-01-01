# https://www.reddit.com/r/PowerShell/comments/7r9ady/retrieving_video_file_metadata/
# https://stackoverflow.com/questions/25690038/how-do-i-properly-use-the-folderbrowserdialog-in-powershell
# https://www.powershellmagazine.com/2013/06/28/pstip-using-the-system-windows-forms-folderbrowserdialog-class/
# https://powershellone.wordpress.com/2016/05/06/powershell-tricks-open-a-dialog-as-topmost-window/

<#
    Author: Mohamed Ali Ramadan
    Date Created: 2018/12/31
    Last Modified By: Mohamed Ali Ramadan
    Last Modified:
    --------------------------------------------------------------------------------
    Description:
    This script...
#>

# Add assemblies
Add-Type -AssemblyName System.Windows.Forms

Function Select-FolderBrowserPath
{
    <#
    $FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $FolderBrowser.Description = 'Select the folder containing the data'
    $result = $FolderBrowser.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true }))
    if ($result -eq [Windows.Forms.DialogResult]::OK){
        $FolderBrowser.SelectedPath
    }
    else {
        exit
    }
    #>






    $FolderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog -Property @{ 
        #SelectedPath = 'C:\Temp'
        Description = 'test'
        ShowNewFolderButton = $false

    }
     
    $FolderBrowserDialog.ShowDialog()
    $FolderBrowserDialog.BringToFront()

    $FolderBrowserDialog.SelectedPath # Return value on pipeline
    return
}

$FolderPathToProcess = Select-FolderBrowserPath

Write-Host "The folder path selected is: $FolderPathToProcess"