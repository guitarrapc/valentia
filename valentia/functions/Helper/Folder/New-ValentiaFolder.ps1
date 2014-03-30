﻿#Requires -Version 3.0

#-- Prerequisite Deploy Setting Module Functions --#

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
function New-ValentiaFolder
{
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
            HelpMessage = "Branch Path path.")]
        [ValentiaBranchPath[]]
        $BranchPath,

        [Parameter(
            Position = 2,
            Mandatory = 0,
            HelpMessage = "Log Folder path.")]
        $LogFolder = $valentia.Log.path,

        [Parameter(
            Position = 3,
            Mandatory = 0,
            HelpMessage = "Suppress output directory create info.")]
        [switch]
        $Quiet
    )

    begin
    {
        # Create Fullpath String
        if ($BranchPath.Length -eq 0)
        {
            $DeployFolders = [Enum]::GetNames([ValentiaBranchPath]) | %{Join-Path $RootPath $_}
        }
        else
        {
            $DeployFolders = $BranchPath | %{Join-Path $RootPath $_}
        }

        $directories = New-Object System.Collections.Generic.List[System.IO.DirectoryInfo]
    }

    process
    {
        # Check each Fupllpath and create if not exist.
        foreach ($Deployfolder in $DeployFolders)
        {
            if(-not (Test-Path $DeployFolder))
            {
                ("'{0}' not exist, creating." -f $DeployFolder) | Write-ValentiaVerboseDebug
                $output = New-Item -Path $DeployFolder -ItemType directory -Force
                $directories.Add($output)
            }
            else
            {
                ("'{0}' already exist, skip." -f $DeployFolder) | Write-ValentiaVerboseDebug
                $output = Get-Item -Path $DeployFolder
                $directories.Add($output)
            }
        }

        # Check Log Folder and create if not exist 
        if(-not (Test-Path $LogFolder))
        {
            ("'{0}' not exist, creating." -f $LogFolder) | Write-ValentiaVerboseDebug
            $output = New-Item -Path $LogFolder -ItemType directory -Force
            $directories.Add($output)
        }
        else
        {
            ("'{0}' already exist, skip." -f $LogFolder) | Write-ValentiaVerboseDebug
            $output = Get-Item -Path $LogFolder
            $directories.Add($output)
        }
    }

    end
    {
        if (-not $Quiet)
        {
            $directories
        }

        # Cleanup valentia Environment
        Invoke-ValentiaClean
    }

}
