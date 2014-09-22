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

        $zip = New-ValentiaZipPairs -first $SourceFolder -second $DestinationFolder
        foreach ($x in $zip)
        {
            # skip not directory
            if (-not (IsDirectory -Path $x.item1)){ Write-Warning ("SourceFolder detected as not Directory, skip '{0}'" -f $x.item1); continue;}

            foreach ($member in $valentia.Result.DeployMembers)
            {                
                # Prerequisite
                $robocopy = "robocopy.exe"
                $source = RemoveLastSlashFromPath -Path $x.item1
                $dest = ConcatDeployMemeberWithPath -deploymember $member -Path $x.item2
                $mode = "*.* /MIR /R:3 /W:5"
                $arguments = @("`"$source`"", "`"$dest`"", $mode)

                # ProcessInfo
                $ProcessStartInfo = New-object System.Diagnostics.ProcessStartInfo
                $ProcessStartInfo.CreateNoWindow = $true 
                $ProcessStartInfo.UseShellExecute = $false 
                $ProcessStartInfo.RedirectStandardOutput = $true
                $ProcessStartInfo.RedirectStandardError = $true
                $ProcessStartInfo.FileName = $robocopy
                $ProcessStartInfo.Arguments = $arguments

                # execute
                $process = New-Object System.Diagnostics.Process 
                $process.StartInfo = $ProcessStartInfo
                $process.Start() > $null
                $output = $process.StandardOutput.ReadToEnd()
                $outputError = $process.StandardError.ReadToEnd()
                $process.StandardOutput.ReadLine()
                $process.WaitForExit() 
                    
                # Result
                $output
                $valentia.Result.Result = $output
                $valentia.Result.ScriptToRun += "{0} {1}`r`n" -f $ProcessStartInfo.FileName, $ProcessStartInfo.Arguments
                $valentia.Result.ErrorMessageDetail = $outputError
            }
        }        

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

        function IsFile ([string]$Path)
        {
            if ([System.IO.File]::Exists($Path))
            {
                Write-Verbose ("Input object : '{0}' detected as File." -f $Path)
                return [System.IO.FileInfo]($Path)
            }
        }

        function IsDirectory ([string]$Path)
        {
            if ([System.IO.Directory]::Exists($Path))
            {
                Write-Verbose ("Input object : '{0}' detected as Directory." -f $Path)
                return [System.IO.DirectoryInfo] ($Path)
            }
        }

        function RemoveLastSlashFromPath ([string]$Path)
        {
            $sourceP = Split-Path $Path -Parent
            $sourceL = Split-Path $Path -Leaf
            return $sourceP + "\" + $sourceL
        }

        function RenameToUNCPath ([string]$Path)
        {
            if ($Path.Contains){ return $Path.Replace(":", "$") }
            return $Path
        }

        function ConcatDeployMemeberWithPath ([string]$deploymember, [string]$Path)
        {
            # Local will not use UNC Path
            if ($deploymember -in "127.0.0.1", "localhost", [System.Net.DNS]::GetHostByName("").HostName, [System.Net.DNS]::GetHostByName("").AddressList){ return $Path }
            
            # Only for Remote Host
            $UNCPath = RenameToUNCPath -Path $Path
            return [string]::Concat("\\", $deploymember, "\", $UNCPath)
        }
    }
}
