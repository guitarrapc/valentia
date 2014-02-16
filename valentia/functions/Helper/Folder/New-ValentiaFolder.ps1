#Requires -Version 3.0

#-- Prerequisite Deploy Setting Module Functions --#

function New-ValentiaFolder
{

<#

.SYNOPSIS 
Configure Deployment Path

.DESCRIPTION
This cmdlet will create valentis deploy folders for each Branch path.

.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
New-valentiaFolder
--------------------------------------------
create as default

#>

    [CmdletBinding()]
    param
    (
        [Parameter(
            Position = 0,
            Mandatory = 0,
            HelpMessage = "Root Folder path.")]
        [string]
        $RootPath = $valentia.RootPath,

        [Parameter(
            Position = 1,
            Mandatory = 0,
            HelpMessage = "Branch Folder path.")]
        [string[]]
        $BranchFolder,

        [Parameter(
            Position = 2,
            Mandatory = 0,
            HelpMessage = "Log Folder path.")]
        $LogFolder = $valentia.Log.path
    )

    begin
    {
        # Create Fullpath String
        if ($BranchFolder.Length -eq 0)
        {
            "BranchFolder detected as empty. using $($valentia.BranchFolder) for BranchFolder name" | Write-ValentiaVerboseDebug
            $pname = $valentia.BranchFolder | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name
            $DeployFolders = $pname | %{Join-Path $RootPath $_}
        }
        else
        {
            ("BranchFolder detected as {0}" -f $BranchFolder) | Write-ValentiaVerboseDebug
            $DeployFolders = $BranchFolder | %{Join-Path $RootPath $_}
        }
    }

    process
    {
        # Check each Fupllpath and create if not exist.
        foreach ($Deployfolder in $DeployFolders)
        {
            if(!(Test-Path $DeployFolder))
            {
                ("{0} not exist, creating {1}." -f $DeployFolder, $DeployFolder) | Write-ValentiaVerboseDebug
                New-Item -Path $DeployFolder -ItemType directory -Force > $null
            }
            else
            {
                ("{0} already exist, skip create {1}." -f $DeployFolder, $DeployFolder) | Write-ValentiaVerboseDebug
            }
        }

        # Check Log Folder and create if not exist 
        if(!(Test-Path $LogFolder))
        {
            ("{0} not exist, creating {1}." -f $LogFolder, $LogFolder) | Write-ValentiaVerboseDebug
            New-Item -Path $LogFolder -ItemType directory -Force > $null
        }
        else
        {
            ("{0} already exist, skip create {1}." -f $LogFolder, $LogFolder) | Write-ValentiaVerboseDebug
        }

    }

    end
    {
        Write-Warning ("`nDisplay all deployFolders existing at [ {0} ]" -f $RootPath)
        (Get-ChildItem -Path $RootPath).FullName

        Write-Warning ("`nDisplay Logfolders existing at [ {0} ]" -f $LogFolder)
        (Get-ChildItem -Path $LogFolder).FullName

        # Cleanup valentia Environment
        Invoke-ValentiaClean
    }

}
