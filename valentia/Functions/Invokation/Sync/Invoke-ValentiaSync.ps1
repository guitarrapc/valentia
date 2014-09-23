#Requires -Version 3.0

#-- Public Module Functions for Sync Files or Directories--#

# Sync

<#
.SYNOPSIS 
Use robocopy.exe to Sync Folder for Diff folder/files not consider Diff from remote server.

.DESCRIPTION
Robocopy is Windows Standard utility and it is wrapper to use simple.

.NOTES
Author: gutiarrapc
Created: 13/July/2013

.EXAMPLE
Sync -Source sourcepath -Destination desitinationSharePath -DeployGroup DeployGroup.ps1
--------------------------------------------
Sync sourthpath and destinationsharepath directory in Diff mode. (Will not delete items but only update to add new)

.EXAMPLE
Sync c:\deployment\upload c:\deployment\upload 192.168.1.100
--------------------------------------------
Sync c:\deployment\upload directory and remote server listed in new.ps1 c:\deployment\upload directory in Diff mode. (Will not delete items but only update to add new)

.EXAMPLE
Sync -Source c:\upload.txt -Destination c:\share\ -DeployGroup 192.168.1.100,192.168.1.102
--------------------------------------------
Sync c:\upload.txt file and c:\share directory in Diff mode. (Will not delete items but only update to add new)
#>
function Invoke-ValentiaSync
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, Mandatory = 1, HelpMessage = "Input Deploy Server Source Folder Sync to Client PC.")]
        [string[]]$SourceFolder, 

        [Parameter(Position = 1, Mandatory = 1, HelpMessage = "Input Client Destination Folder Sync with Desploy Server.")]
        [String[]]$DestinationFolder,

        [Parameter(Position = 2, Mandatory = 1, HelpMessage = "Input target of deploy clients as [DeployGroup filename you sat at deploygroup Folder] or [ipaddress].")]
        [string]$DeployGroups,

        [Parameter(Position = 3, Mandatory = 0, HelpMessage = "Input DeployGroup Folder path if changed.")]
        [string]$DeployFolder = (Join-Path $Script:valentia.RootPath ([ValentiaBranchPath]::Deploygroup)),

        [Parameter(Position = 4, Mandatory = 0, HelpMessage = "Return success result even if there are error.")]
        [bool]$SkipException = $false
    )

    process
    {
        try
        {

        #region Prerequisite
        
            # Prerequisite setup
            $prerequisiteParam = @{
                Stopwatch     = $TotalstopwatchSession
                DeployGroups  = $DeployGroups
                DeployFolder  = $DeployFolder
            }
            Set-ValentiaInvokationPrerequisites @prerequisiteParam

        #endregion

        #region Process

            Invoke-ValentiaRoboCopyMirror -SourceFolder $SourceFolder -DestinationFolder $DestinationFolder

        #endregion

        }
        catch
        {
            $valentia.Result.SuccessStatus += $false
            $valentia.Result.ErrorMessageDetail += $_
            if ($ErrorActionPreference -eq 'Stop')
            {
                throw $_
            }
        }
        finally
        {
            $valentia.Result.ScriptToRun = $valentia.Result.ScriptToRun -join "`r`n"
            # obtain Result
            $resultParam = @{
                StopWatch     = $TotalstopwatchSession
                Cmdlet        = $($MyInvocation.MyCommand.Name)
                TaskFileName  = $TaskFileName
                DeployGroups  = $DeployGroups
                SkipException = $SkipException
                Quiet         = $PSBoundParameters.ContainsKey("quiet")
            }
            Out-ValentiaResult @resultParam

            # Cleanup valentia Environment
            Invoke-ValentiaClean
        }
    }

    begin
    {
        # Initialize Stopwatch
        $TotalstopwatchSession = [System.Diagnostics.Stopwatch]::StartNew()

        # Reset ErrorActionPreference
        if ($PSBoundParameters.ContainsKey('ErrorAction'))
        {
            $originalErrorAction = $ErrorActionPreference
        }
        else
        {
            $originalErrorAction = $ErrorActionPreference = $valentia.preference.ErrorActionPreference.original
        }
    }
}
