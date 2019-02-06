<#
    Author: Mohamed Ali Ramadan
    Date Created: 2018/06/06
    Last Modified By: Mohamed Ali Ramadan
    Last Modified: 2019/02/05
    --------------------------------------------------------------------------------
	Description:
    The purpose of this script is to ensure deleted files in the specified folder on a first network domain
	are also deleted from the specified folder on a second network domain.
	--------------------------------------------------------------------------------
	Notes: 
	1. DOMAIN1 and DOMAIN2 refer to the names of the domains to synchronize file deletions.
	2. This script automatically detects which domain it is running on and executes the
       appropriate logic for that domain.
    3. A key assumption is that DOMAIN1 has the folder which is up-to-date and DOMAIN2
       has the folder that requires scripts to reproduce the changes.
    4. Transfering of the List of Filenames TEXT file is not done by this script,
       as the assumption of DOMAIN2 being secret/private is made.
	--------------------------------------------------------------------------------
    Instructions:
	1. Setup for DOMAIN1 and DOMAIN2 below must be completed by modifying the variable values.
    2. This exact script must be scheduled to run every 20 minutes on both DOMAIN1 and DOMAIN2.
    3. The DOMAIN2 PC should run the script 2-3 minutes AFTER the DOMAIN1 PC runs the script.
#>

# Global setup:

# SETUP 1. Specify the first domain name:
$domain_1_Name = 'DOMAIN1'
# SETUP 2. Specify the second domain name:
$domain_2_Name = 'DOMAIN2'
# SETUP 3. Specify the folder path of the first domain folder to monitor for deleted files.
$domain_1_FolderPath = ''
# SETUP 4. Specify the folder path of the second domain's folder which is to be updated.
$domain_2_FolderPath = ''

# Setup variables used when running on the first domain:

# SETUP 5. Specify the output path for the List of Filenames text file which will be generated.
$outputList_FolderPath = ''
# SETUP 6. Specify the file name for the List of Files text file.
$outputList_FileName = $domain_1_Name + '_files_list_for_deletion_sync' + '.txt'

# Verifies the folder paths provided in SETUP 3 and SETUP 5.
if ((Test-Path -Path $domain_1_FolderPath -PathType Container) -eq $false)
{
    Write-Host "The folder path '$domain_1_FolderPath' specified for the domain_1_FolderPath variable is invalid."
    exit
}
elseif ((Test-Path -Path $outputList_FolderPath -PathType Container) -eq $false)
{
    Write-Host "The folder path '$outputList_FolderPath' specified for the outputList_FolderPath variable is invalid."
    exit
}

# Setup the script for running on the second domain:

# SETUP 7. Specify the folder path on the second domain, where the list of filenames TEXT file will be sent to.
$domain_2_InputFilenamesListFolderPath = 'C:\_domain_2_input'

# SETUP 8. Specify the folder path on the second domain, where the Error Log should be output.
$domain_2_ErrorLogFolderPath = 'C:\_domain_2_error'

# SETUP 9. Specify the folder path on the second domain, where the list of domain 2's folder's filenames can be temporarily stored.
$domain_2_TempFolderPath = 'C:\_domain_2_temp'

# Verifies the folder paths provided in SETUP 4, SETUP 7, SETUP 8, SETUP 9.
if ((Test-Path -Path $domain_2_FolderPath -PathType Container) -eq $false)
{
    Write-Host "The folder path '$domain_2_FolderPath' specified for the domain_2_FolderPath variable is invalid."
    exit
}
elseif ((Test-Path -Path $domain_2_InputFilenamesListFolderPath -PathType Container) -eq $false)
{
    Write-Host "The folder path '$domain_2_InputFilenamesListFolderPath' specified for the domain_2_InputFilenamesListFolderPath variable is invalid."
    exit
}
elseif ((Test-Path -Path $domain_2_ErrorLogFolderPath -PathType Container) -eq $false)
{
    Write-Host "The folder path '$domain_2_ErrorLogFolderPath' specified for the domain_2_ErrorLogFolderPath variable is invalid."
    exit
}
elseif ((Test-Path -Path $domain_2_TempFolderPath -PathType Container) -eq $false)
{
    Write-Host "The folder path '$domain_2_TempFolderPath' specified for the domain_2_TempFolderPath variable is invalid."
    exit
}

# DOMAIN1 and DOMAIN2 logic:

# Obtain domain name of the PC running this script.
$localDomainName = (Get-WmiObject Win32_ComputerSystem).Domain

# If on DOMAIN1, run the script in DOMAIN1 mode.
if($localDomainName -eq $domain_1_Name)
{
    # Combine the output path with the desired filename.
    $outputList_FullFilePath = $outputList_FolderPath + '\' + $outputList_FileName

    # Obtain all child nodes of the DOMAIN1 root folder, including both files and folders/directories.
    $allChildren = Get-ChildItem -Recurse $domain_1_FolderPath

    # Delete an existing DOMAIN2 List of Filenames text file if it exists. This prevents appending to a previous list an causing problems.
    if (Test-Path -Path $outputList_FullFilePath -PathType Leaf)
    {
        Remove-Item -Path $outputList_FullFilePath -Force
    }

    # Process all obtained children.
    foreach ($child in $allChildren)
    {
        # If the child is a File, 
        if (Test-Path -Path $child.FullName -PathType Leaf)  # Tested alternative is:  if ($child.Extension -ne '')
        {
            # Write the file's Full File Path to the output text file.
            Out-File -FilePath $outputList_FullFilePath -Append -InputObject $child.FullName
        }
    }

    # After this, the file must be sent over to DOMAIN2's input folder path using DialNet (assuming DOMAIN2 is private).
}
# If on DOMAIN2, run the script in DOMAIN2 mode.
elseif ($localDomainName -eq $domain_2_Name)
{
    # Calculate the full file paths for the required files.
    $domain_2_InputFilenamesListFilePath = $domain_2_InputFilenamesListFolderPath + '\' + $outputList_FileName
    $domain_2_ErrorLogFilePath = $domain_2_ErrorLogFolderPath + "\DeletionSyncErrorLog.txt"
    $domain_2_TempFilePath = $domain_2_TempFolderPath + '\domain_2_temp_files_list.txt'

    # Verify that the input file exists.
    if ((Test-Path -Path $domain_2_InputFilenamesListFilePath -PathType Leaf) -eq $false)
    {
        # Log error and exit script.
        $currentTime = (Get-Date).ToString()
        Out-File -FilePath $domain_2_ErrorLogFilePath -Append -InputObject "$currentTime : ERROR = No Bnet Intranet File List text file was found."
        Write-Host "ERROR = No $domain_1_Name List of Filenames text file was found."
        exit
    }

    # Delete any existing temp file if it exists.
    if (Test-Path -Path $domain_2_TempFilePath -PathType Leaf)
    {
        Remove-Item -Path $domain_2_TempFilePath -Force
    }

    # Obtain all child nodes of DOMAIN2's folder.
    $allChildren = Get-ChildItem -Recurse $domain_2_FolderPath
    # Process all obtained children.
    foreach ($child in $allChildren)
    {
        # If the child is a File, 
        if (Test-Path -Path $child.FullName -PathType Leaf)  # Tested alternative is:  if ($child.Extension -ne '')
        {
            # Write the file's Full File Path to the output text file.
            Out-File -FilePath $domain_2_TempFilePath -Append -InputObject $child.FullName
        }
    }

    # [System.IO.File]::ReadAllLines(string path) Returns an array of .Net strings.

    # Generate an array of strings for each line (file path) from the CABNET Intranet File List text file.
    $domain_2_FilesList = [System.IO.File]::ReadAllLines($domain_2_TempFilePath)
    # Generate an array of strings for each line (file path) from the BNET Intranet File List text file.
    $domain_1_FilesList = [System.IO.File]::ReadAllLines($domain_2_InputFilenamesListFilePath)

    # Verify that both generated array are not empty. If there is an issue log an error and exit.
    if ($domain_1_FilesList.Length -eq 0)
    {
        # Log error and exit script.
        $currentTime = (Get-Date).ToString()
        Out-File -FilePath $domain_2_ErrorLogFilePath -Append -InputObject "$currentTime : ERROR = The $domain_1_Name folder currently has zero files. Please verify the situation."
        Write-Host "ERROR = The $domain_1_Name folder currently has zero files. Please verify the situation."
        exit
    }
    elseif ($domain_2_FilesList.Length -eq 0)
    {
        # Log error and exit script.
        $currentTime = (Get-Date).ToString()
        Out-File -FilePath $domain_2_ErrorLogFilePath -Append -InputObject "$currentTime : ERROR = The $domain_2_Name folder currently has zero files. Please verify the situation."
        Write-Host "ERROR = The $domain_2_Name folder currently has zero files. Please verify the situation."
        exit
    }

    # Convert the $domain_1_FilesList string array into a hashset of strings.
    $domain_1_FilesHashSet = new-object System.Collections.Generic.HashSet[string]
    foreach ($domain_1_file in $domain_1_FilesList)
    {
        $domain_1_FilesHashSet.Add($domain_1_file)
    }

    # Check every file in DOMA?IN2.
    foreach ($domain_2_file in $domain_2_FilesList)
    {
        # Complexity of O(1) check to see if the DOMAIN2 file is not in the DOMAIN1 list.
        if ($domain_1_FilesHashSet.Contains($domain_2_file) -eq $false)
        {
            Remove-Item -Path $domain_2_file -Force  
        }
    }

    # Delete the two text files used for comparision.
    Remove-Item -Path $domain_2_InputFilenamesListFilePath -Force  
    Remove-Item -Path $domain_2_TempFilePath -Force  
}
else 
{
    Write-Host "Script should only be run on domains: $domain_1_Name OR $domain_2_Name"
}