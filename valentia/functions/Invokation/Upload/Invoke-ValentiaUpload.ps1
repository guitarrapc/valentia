#Requires -Version 3.0

#-- Public Module Functions for Upload Files --#

# upload

<#
.SYNOPSIS 
Use BITS Transfer to upload a file to remote server.

.DESCRIPTION
This function supports multiple file transfer, if you want to fix file in list then use uploadList function.
  
.NOTES
Author: guitarrapc
Created: 13/July/2013

.EXAMPLE
upload -SourcePath C:\hogehoge.txt -DestinationPath c:\ -DeployGroup production-first.ps1 -File
--------------------------------------------
upload file to destination for hosts written in production-first.ps1

.EXAMPLE
upload -SourcePath C:\deployment\Upload -DestinationPath c:\ -DeployGroup production-first.ps1 -Directory
--------------------------------------------
upload folder to destination for hosts written in production-first.ps1

.EXAMPLE
upload C:\hogehoge.txt c:\ production-first -Directory production-fist.ps1 -Async
--------------------------------------------
upload folder as Background Async job for hosts written in production-first.ps1

.EXAMPLE
upload C:\hogehoge.txt c:\ production-first -Directory 192.168.0.10 -Async
--------------------------------------------
upload file to Directory as Background Async job for host ip 192.168.0.10

.EXAMPLE
upload C:\hogehoge* c:\ production-first -Directory production-fist.ps1 -Async
--------------------------------------------
upload files in target to Directory as Background Async job for hosts written in production-first.ps1
#>
function Invoke-ValentiaUpload
{
    [CmdletBinding(DefaultParameterSetName = "File")]
    param
    (
        [Parameter(
            Position = 0,
            Mandatory,
            HelpMessage = "Input Deploy Server SourcePath to be uploaded.")]
        [string]
        $SourcePath, 

        [Parameter(
            Position = 1,
            Mandatory,
            HelpMessage = "Input Clinet DestinationPath to save upload items.")]
        [String]
        $DestinationPath = $null,

        [Parameter(
            Position = 2,
            Mandatory,
            HelpMessage = "Input target of deploy clients as [DeployGroup filename you sat at deploygroup Folder] or [ipaddress].")]
        [string]
        $DeployGroups,

        [Parameter(
            position = 3,
            Mandatory = 0,
            ParameterSetName = "File",
            HelpMessage = "Set this switch to execute command for File. exclusive with Directory Switch.")]
        [switch]
        $File = $null,

        [Parameter(
            position = 3,
            Mandatory = 0,
            ParameterSetName = "Directory",
            HelpMessage = "Set this switch to execute command for Directory. exclusive with File Switch.")]
        [switch]
        $Directory,

        [Parameter(
            Position = 4,
            Mandatory = 0,
            HelpMessage = "Set this switch to execute command as Async (Job).")]
        [switch]
        $Async = $false,

        [Parameter(
            Position = 5,
            Mandatory = 0,
            HelpMessage = "Input DeployGroup Folder path if changed from default.")]
        [string]
        $DeployFolder = (Join-Path $Script:valentia.RootPath ([ValentiaBranchPath]::Deploygroup)),

        [Parameter(
            Position = 6,
            Mandatory = 0,
            HelpMessage = "Return success result even if there are error.")]
        [bool]
        $SkipException = $false
    )

    try
    {

    ### Begin

        $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
    
        # Initialize Stopwatch
        [decimal]$TotalDuration = 0
        $TotalstopwatchSession = [System.Diagnostics.Stopwatch]::StartNew()
            
        # Initialize Errorstatus
        $SuccessStatus = $ErrorMessageDetail = @()

        # Get Start Time
        $TimeStart = (Get-Date).DateTime

        # Import default Configurations & Modules
        if ($PSBoundParameters['Verbose'])
        {
            # Import default Configurations
            $valeWarningMessages.warn_import_configuration | Write-ValentiaVerboseDebug
            Import-ValentiaConfiguration -Verbose

            # Import default Modules
            $valeWarningMessages.warn_import_modules | Write-ValentiaVerboseDebug
            Import-valentiaModules -Verbose
        }
        else
        {
            Import-ValentiaConfiguration
            Import-valentiaModules
        }

        # Log Setting
        New-ValentiaLog     

        # Obtain Remote Login Credential
        try
        {
            $Credential = Get-ValentiaCredential -Verbose:$VerbosePreference
            $SuccessStatus += $true
        }
        catch
        {
            Write-Error $_
            $SuccessStatus += $false
        }


        # Obtain DeployMember IP or Hosts for BITsTransfer
        "Get hostaddresses to connect." | Write-ValentiaVerboseDebug
        $DeployMembers = Get-valentiaGroup -DeployFolder $DeployFolder -DeployGroup $DeployGroups

        # Parse Network Destination Path
        ("Parsing Network Destination Path {0} as :\ should change to $." -f $DestinationFolder) | Write-ValentiaVerboseDebug
        $DestinationPath = "$DestinationPath".Replace(":","$")

        # Show Stopwatch for Begin section
        $TotalDuration = $TotalstopwatchSession.Elapsed.TotalSeconds
        Write-Verbose ("`t`tDuration Second for Begin Section: {0}" -f $TotalDuration)
        ""


    ### Process

        ("Uploading {0} to Target Computer : [{1}] `n" -f $SourcePath, $DeployMembers) | Write-ValentiaVerboseDebug

        # Stopwatch
        [decimal]$DurationTotal = 0

        # Create PSSession  for each DeployMember
        foreach ($DeployMember in $DeployMembers)
        {
            # Stopwatch
            $stopwatchSession = [System.Diagnostics.Stopwatch]::StartNew()
    
            # Set Destination
            $Destination = Join-Path "\\" $(Join-Path "$DeployMember" "$DestinationPath")

            if ($Directory)
            {
                # Set Source files in source
                try
                {
                    # No recurse
                    $SourceFiles = Get-ChildItem -Path $SourcePath
                }
                catch
                {
                    $SuccessStatus += $false
                    $ErrorMessageDetail += $_
                    throw $_
                }
            }
            elseif ($File)
            {
                # Set Source files in source
                try
                {
                    # No recurse
                    $SourceFiles = Get-Item -Path $SourcePath
                    
                    if ($SourceFiles.Attributes -eq "Directory")
                    {
                        $SuccessStatus += $false
                        $ErrorMessageDetail += "Target is Directory, you must set Filename with -File Switch."
                        throw "Target is Directory, you must set Filename with -File Switch."
                    }
                }
                catch
                {
                    $SuccessStatus += $false
                    $ErrorMessageDetail += $_
                    throw $_
                }
            }
            else
            {
                $SuccessStatus += $false
                $ErrorMessageDetail += $_
                throw "Missing File or Directory switch. Please set -File or -Directory Switch to specify download type."
            }


            # Show Start-BitsTransfer Parameter
            Write-Warning ("[{0}]:Uploading {1} to {2}." -f $DeployMember,"$($SourceFiles.Name)", $Destination)
            Write-Verbose ("DestinationDeployFolder : {0}" -f $DeployFolder)
            Write-Verbose ("Aync Mode : {0}" -f $Async)

            if (Test-Path $SourcePath)
            {
                try
                {
                    switch ($true)
                    {
                        # Async Transfer
                        $Async {                    
                            $ScriptToRun = "Start-BitsTransfer -Source $(($Sourcefile).FullName) -Destination $Destination -Credential $Credential -Asynchronous -DisplayName $DeployMember -Priority High -TransferType Upload"
                            try
                            {
                                foreach ($SourceFile in $SourceFiles)
                                {
                                    try
                                    {
                                        # Run Job
                                        ("Running Async Job upload to {0}" -f $DeployMember) | Write-ValentiaVerboseDebug
                                        $Job = Start-BitsTransfer -Source $(($Sourcefile).FullName) -Destination $Destination -Credential $Credential -Asynchronous -DisplayName $DeployMember -Priority High -TransferType Upload

                                        # Waiting for complete job
                                        $Sleepms = 10
                                    }
                                    catch
                                    {
                                        $SuccessStatus += $false
                                        $ErrorMessageDetail += $_

                                        # Show Error Message
                                        throw $_
                                    }

                                }

                                $Sleepms = 10
                                # Retrieving transfer status and monitor for transffered
                                while (((Get-BitsTransfer).JobState -contains "Transferring") -or ((Get-BitsTransfer).JobState -contains "Connecting") -or ((Get-BitsTransfer).JobState -contains "Queued")) `
                                { 
                                    ("Current Job States was {0}, waiting for {1}ms {2}" -f ((Get-BitsTransfer).JobState | sort -Unique), $Sleepms, (((Get-BitsTransfer | where JobState -eq "Transferred").count) / $((Get-BitsTransfer).count))) | Write-ValentiaVerboseDebug
                                    Sleep -Milliseconds $Sleepms
                                }

                                # Retrieve all files when completed
                                Get-BitsTransfer | Complete-BitsTransfer
                            }
                            catch
                            {
                                $SuccessStatus += $false
                                $ErrorMessageDetail += $_

                                # Show Error Message
                                throw $_
                            }
                            finally
                            {
                                # Delete all not compelte job
                                Get-BitsTransfer | Remove-BitsTransfer

                                # Stopwatch
                                $Duration = $stopwatchSession.Elapsed.TotalSeconds
                                Write-Verbose ("Session duration Second : {0}" -f $Duration)
                                ""
                                $DurationTotal += $Duration
                            }

                        }
                        # NOT Async Transfer
                        default {
                            $ScriptToRun = "Start-BitsTransfer -Source $(($SourceFiles).fullname) -Destination $Destination -Credential $Credential -TransferType"

                            try
                            {
                                foreach($SourceFile in $SourceFiles)
                                {
                                    #Only start upload for file.
                                    if (-not((Get-Item $SourceFile.fullname).Attributes -eq "Directory"))
                                    {
                                        ("Uploading {0} to {1}'s {2}" -f $(($SourceFile).fullname), $DeployMember, $Destination) | Write-ValentiaVerboseDebug
                                        Start-BitsTransfer -Source $(($SourceFile).fullname) -Destination $Destination -Credential $Credential
                                    }
                                }
                            }
                            catch [System.Management.Automation.ActionPreferenceStopException]
                            {
                                $SuccessStatus += $false
                                $ErrorMessageDetail += $_

                                # Show Error Message
                                throw $_
                            }
                            finally
                            {
                                # Delete all not compelte job
                                Get-BitsTransfer | Remove-BitsTransfer

                                # Stopwatch
                                $Duration = $stopwatchSession.Elapsed.TotalSeconds
                                Write-Verbose ("Session duration Second : {0}" -f $Duration)
                                ""
                            }
                        }
                    }
                }
                catch
                {

                    # Show Error Message
                    Write-Error $_

                    # Set ErrorResult
                    $SuccessStatus += $false
                    $ErrorMessageDetail += $_

                }
            }
            else
            {
                Write-Warning ("{0} could find from {1}. Skip to next." -f $Source, $DeployGroups)
            }
        }

    ### End

    }
    catch
    {

        $SuccessStatus += $false
        $ErrorMessageDetail += $_
        if (-not $SkipException)
        {
            throw $_
        }
    }
    finally
    {
        # Stopwatch
        $TotalDuration = $TotalstopwatchSession.Elapsed.TotalSeconds
        Write-Verbose ("`t`tTotal duration Second`t: {0}" -f $TotalDuration)
        "" | Out-Default

        # Get End Time
        $TimeEnd = (Get-Date).DateTime

        # obtain Result
        $CommandResult = [ordered]@{
            Success = !($SuccessStatus -contains $false)
            TimeStart = $TimeStart
            TimeEnd = $TimeEnd
            TotalDuration = $TotalDuration
            Module = "$($MyInvocation.MyCommand.Module)"
            Cmdlet = "$($MyInvocation.MyCommand.Name)"
            Alias = "$((Get-Alias -Definition $MyInvocation.MyCommand.Name).Name)"
            ScriptBlock = "$ScriptToRun"
            DeployGroup = "$DeployGroups"
            TargetHosCount = $($DeployMembers.count)
            TargetHosts = "$DeployMembers"
            SkipException  = $SkipException
            ErrorMessage = $($ErrorMessageDetail | where {$_ -ne $null} | sort -Unique)
        }

        # show result
        WriteValentiaResultHost -quiet $PSBoundParameters.ContainsKey("quiet") -CommandResult $CommandResult

        # output result
        OutValentiaResultLog -CommandResult $CommandResult

        # Cleanup valentia Environment
        Invoke-ValentiaClean

    }
}
