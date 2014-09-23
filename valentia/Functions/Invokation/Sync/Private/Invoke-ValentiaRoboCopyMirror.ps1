#Requires -Version 3.0

#-- Private Module Job / Functions for Remote Execution --#

<#
.SYNOPSIS 
Invoke Command as Job to remote host

.DESCRIPTION
Background job execution with Invoke-Command.
Allowed to run from C# code.

.NOTES
Author: guitarrapc
Created: 20/June/2013

.EXAMPLE
  Invoke-ValentiaCommand -ScriptToRun $ScriptToRun

.EXAMPLE
  Invoke-ValentiaCommand -ScriptToRun {ls}

.EXAMPLE
  Invoke-ValentiaCommand -ScriptToRun {ls | where {$_.extensions -eq ".txt"}}

.EXAMPLE
  Invoke-ValentiaCommand {test-connection localhost}
#>
function Invoke-ValentiaRoboCopyMirror
{
    [CmdletBinding(DefaultParameterSetName = "All")]
    param
    (
        [Parameter(Position = 0, Mandatory = 1, ValueFromPipelineByPropertyName = 1)]
        [string[]]$SourceFolder,

        [Parameter(Position = 1, Mandatory = 1, ValueFromPipelineByPropertyName = 1)]
        [string[]]$DestinationFolder
    )

    process
    {
        $zip = New-ValentiaZipPairs -first $SourceFolder -second $DestinationFolder
        foreach ($x in $zip)
        {
            # skip if not directory
            if (-not (Test-Path -Path $x.item1)){ Write-Warning ("SourcePath not found. skip '{0}'" -f $x.item1); continue; }
            
            # sourceFullPath Resolver
            $sourceFullPath = ResolveToAbsolutePath -Path $x.item1
            if (-not (IsDirectory -Path $sourceFullPath)){ Write-Warning ("SourcePath detected as not Directory, skip '{0}'" -f $x.item1); continue; }

            foreach ($member in $valentia.Result.DeployMembers)
            {                
                # Prerequisite
                $robocopy = "robocopy.exe"
                $source = RemoveLastSlashFromPath -Path $sourceFullPath
                $dest = ConcatDeployMemeberWithPath -deploymember $member -Path $x.item2
                $mode = "*.* /S /E /DCOPY:DA /COPY:DAT /PURGE /MIR /R:3 /W:5"
                $arguments = @("`"$source`"", "`"$dest`"", $mode)

                try
                {
                    # processInfo
                    $processStartInfo = New-object System.Diagnostics.ProcessStartInfo
                    $processStartInfo.CreateNoWindow = $true 
                    $processStartInfo.UseShellExecute = $false 
                    $processStartInfo.RedirectStandardOutput = $true
                    $processStartInfo.RedirectStandardError = $true
                    $processStartInfo.FileName = $robocopy
                    $processStartInfo.Arguments = $arguments

                    # execute process
                    $process = New-Object System.Diagnostics.Process 
                    $process.StartInfo = $processStartInfo
                    $process.Start() > $null
                    $output = $process.StandardOutput.ReadToEnd()
                    $outputError = $process.StandardError.ReadToEnd()
                    $process.StandardOutput.ReadLine()
                    $process.WaitForExit() 
                    
                    # get result
                    $output
                    $valentia.Result.Result.Add($output)
                    $valentia.Result.ScriptToRun.Add(("{0} {1}" -f $processStartInfo.FileName, $processStartInfo.Arguments))
                    $valentia.Result.ErrorMessageDetail = $outputError
                }
                finally
                {
                    # dispose
                    if ($null -ne $processStartInfo){ $processStartInfo = $null }
                    if ($null -ne $process){ $process.Dispose() }
                }
            }
        }        
    }

    begin
    {
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
            if ("\" -eq ([System.Linq.Enumerable]::ToArray($Path) | select -Last 1))
            {
                $sourceP = Split-Path $Path -Parent
                $sourceL = Split-Path $Path -Leaf
                return $sourceP + $sourceL
            }
            return $Path
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

        function ResolveToAbsolutePath ([string]$Path)
        {
            return (Resolve-Path $x.item1).Path
        }
    }
}