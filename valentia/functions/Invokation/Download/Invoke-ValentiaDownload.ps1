#Requires -Version 3.0

#-- Public Module Functions for Download Files --#

# download

<#
.SYNOPSIS 
Use BITS Transfer to downlpad a file from remote server.
If -Force switch enable, then use smbmapping and copy -force will run.

.DESCRIPTION
If target path was directory then download files below path. (None recurse)
If target path was file then download specific file.

.NOTES
Author: guitarrapc
Created: 14/Aug/2013

.EXAMPLE
download -SourcePath c:\logs\white\20130719 -DestinationFolder c:\logs\white -DeployGroup production-g1.ps1 -Directory -Async
--------------------------------------------
download remote sourthdirectory items to local destinationfolder in backgroud job.

.EXAMPLE
download -SourcePath c:\logs\white\20130716\Http.0001.log -DestinationFolder c:\test -DeployGroup.ps1 production-first -File
--------------------------------------------
download remote sourth item to local destinationfolder

.EXAMPLE
download -SourcePath c:\logs\white\20130716 -DestinationFolder c:\test -DeployGroup production-first.ps1 -Directory
--------------------------------------------
download remote sourthdirectory items to local destinationfolder in backgroud job. Omit parameter name.
#>
function Invoke-ValentiaDownload
{
    [CmdletBinding(DefaultParameterSetName = "File")]
    param
    (
        [Parameter(
            Position = 0,
            Mandatory,
            HelpMessage = "Input Client SourcePath to be downloaded.")]
        [String]
        $SourcePath,

        [Parameter(
            Position = 1,
            Mandatory,
            HelpMessage = "Input Server Destination Folder to save download items.")]
        [string]
        $DestinationFolder = $null, 

        [Parameter(
            Position = 2,
            Mandatory,
            HelpMessage = "Input target of deploy clients as [DeployGroup filename you sat at deploygroup Folder] or [ipaddress].")]
        [string]
        $DeployGroups,

        [Parameter(
            position = 3,
            ParameterSetName = "File",
            HelpMessage = "Set this switch to execute command for File. exclusive with Directory Switch.")]
        [switch]
        $File = $true,

        [Parameter(
            position = 3,
            ParameterSetName = "Directory",
            HelpMessage = "Set this switch to execute command for Directory. exclusive with File Switch.")]
        [switch]
        $Directory,

        [Parameter(
            position = 4,
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
            HelpMessage = "Set this switch if you want to Force download. This will smbmap with source folder and Copy-Item -Force. (default is BitTransfer)")]
        [switch]
        $force = $false
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
        $LogPath = New-ValentiaLog
        
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
        $DeployMembers = Get-ValentiaGroup -DeployFolder $DeployFolder -DeployGroup $DeployGroups
        
        if ($DeployMembers.SuccessStatus -eq $false)
        {
            $SuccessStatus += $DeployMembers.SuccessStatus
            $ErrorMessageDetail += $DeployMembers.ErrorMessageDetail
        }        
        
        # Parse Network Source
        ("Parsing Network SourcePath {0} as :\ should change to $." -f $SourcrePath) | Write-ValentiaVerboseDebug
        $SourcePath = "$SourcePath".Replace(":","$")


        # Show Stopwatch for Begin section
        $TotalDuration = $TotalstopwatchSession.Elapsed.TotalSeconds
        Write-Verbose ("`t`tDuration Second for Begin Section: {0}" -f $TotalDuration)
        ""
        
    ### Process
    
        ("Downloading {0} from Target Computer : [{1}] `n" -f $SourcePath, $DeployMembers) | Write-ValentiaVerboseDebug

        # Stopwatch
        [decimal]$DurationTotal = 0

        # Create PSSession  for each DeployMember
        foreach ($DeployMember in $DeployMembers){
            
            # Stopwatch
            $stopwatchSession = [System.Diagnostics.Stopwatch]::StartNew()
    
            # Set Source 
            $Source = Join-Path "\\" $(Join-Path "$DeployMember" "$SourcePath")

            if (Test-Path $Source)
            {
                if ($Directory)
                {
                    # Set Source files in source
                    try
                    {
                        # Remove last letter of \ or /
                        if (($Source[-1] -eq "\") -or ($Source[-1] -eq "/"))
                        {
                            $Source = $Source.Substring(0,($Source.Length-1))
                        }

                        # Get File Information - No recurse
                        $SourceFiles = Get-ChildItem -Path $Source
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
                        # Get File Information
                        $SourceFiles = Get-Item -Path $Source
                    
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


                # Set Destination with date and DeproyMemberName
                if ($DestinationFolder -eq $null)
                {
                    $DestinationFolder = $(Join-Path $Script:valentia.RootPath ([ValentiaBranchPath]::Download))
                }

                $Date = (Get-Date).ToString("yyyyMMdd")
                $DestinationPath = Join-Path $DestinationFolder $Date
                $Destination = Join-Path $DestinationPath $DeployMember

                # Create Destination if not exist
                if (-not(Test-Path $Destination))
                {
                    New-Item -Path $Destination -ItemType Directory -Force > $null
                }

                if ($force)
                {
                    # Show Start-BitsTransfer Parameter
                    ("Downloading {0} from {1}." -f $SourceFiles, $DeployMember) | Write-ValentiaVerboseDebug
                    Write-Verbose ("DeployFolder : {0}" -f $DeployFolder)
                    Write-Verbose ("DeployMembers : {0}" -f $DeployMembers)
                    Write-Verbose ("DeployMember : {0}" -f $DeployMember)
                    Write-Verbose ("Source : {0}" -f $Source)
                    Write-Verbose ("Destination : {0}" -f $Destination)
                    Write-Verbose "Aync Mode : You cannot use Async switch with force"

                    # Get Cimsession for target Computer
                    "cim : New-CimSession to the ComputerName '{0}'" -f $DeployMember | Write-ValentiaVerboseDebug
                    $cim = New-CimSession -Credential $Credential -ComputerName $DeployMember
                        
                    # Create SMB Mapping to target parent directory
                    if ($Directory)
                    {
                        "Directory switch Selected" | Write-ValentiaVerboseDebug
                        $smbRemotePath = (Get-Item $Source).FullName
                    }
                    elseif ($file)
                    {
                        "File switch Selected" | Write-ValentiaVerboseDebug
                        $smbRemotePath = (Get-Item $source).DirectoryName
                    }

                    # Running Copy-Item cmdlet, switch with $force
                    try
                    {                     
                        #Only start download for file.
                        foreach($SourceFile in $SourceFiles)
                        {
                            if (-not((Get-Item $SourceFile.fullname).Attributes -eq "Directory"))
                            {
                                Write-Warning ("Downloading {0} from {1} to {2}" -f ($SourceFile).fullname, $DeployMember, $Destination)
                                $ScriptToRun = "Copy-Item -Path $(($SourceFile).fullname) -Destination $Destination -Force"
                                Copy-Item -Path $(($SourceFile).fullname) -Destination $Destination -Force
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
                        # Stopwatch
                        $Duration = $stopwatchSession.Elapsed.TotalSeconds
                        Write-Verbose ("Session duration Second : {0}" -f $Duration)
                        ""
                    }
                }
                else # Not Force Swtich
                {
                    # Show Start-BitsTransfer Parameter
                    ("Downloading {0} from {1}." -f $SourceFiles, $DeployMember) | Write-ValentiaVerboseDebug
                    Write-Verbose ("DeployFolder : {0}" -f $DeployFolder)
                    Write-Verbose ("DeployMembers : {0}" -f $DeployMembers)
                    Write-Verbose ("DeployMember : {0}" -f $DeployMember)
                    Write-Verbose ("Source : {0}" -f $Source)
                    Write-Verbose ("Destination : {0}" -f $Destination)
                    Write-Verbose ("Aync Mode : {0}" -f $Async)

                    # Running Bits Transfer, switch with $Async and no $Async
                    try
                    {
                        switch ($true)
                        {
                            # Async Transfer
                            $Async {
                                try
                                {
                                    $ScriptToRun = "Start-BitsTransfer -Source $(($SourceFile).fullname) -Destination $Destination -Credential $Credential -Asynchronous -DisplayName $DeployMember -Priority High -TransferType Download"
                                    foreach($SourceFile in $SourceFiles)
                                    {
                                        try
                                        {
                                            #Only start download for file.
                                            if (-not((Get-Item $SourceFile.fullname).Attributes -eq "Directory"))
                                            {
                                                # Run Job
                                                Write-Warning ("Async Downloading {0} from {1} to {2}" -f ($SourceFile).fullname, $DeployMember, $Destination)
                                                $Job = Start-BitsTransfer -Source $(($SourceFile).fullname) -Destination $Destination -Credential $Credential -Asynchronous -DisplayName $DeployMember -Priority High -TransferType Download
                                        
                                                # Waiting for complete job
                                                $Sleepms = 10

                                                "Current States was {0}" -f $Job.JobState | Write-ValentiaVerboseDebug
                                            }
                                        }
                                        catch
                                        {
                                            $SuccessStatus += $false
                                            $ErrorMessageDetail += $_

                                            # Show Error Message
                                            throw $_
                                        }
                                    }

                                    # Retrieving transfer status and monitor for transffered
                                    $Sleepms = 10
                                    while (((Get-BitsTransfer).JobState -contains "Transferring") -or ((Get-BitsTransfer).JobState -contains "Connecting") -or ((Get-BitsTransfer).JobState -contains "Queued")) `
                                    { 
                                        "Current Job States was {0}, waiting for {1} ms {2}" -f ((Get-BitsTransfer).JobState | sort -Unique), $Sleepms, (((Get-BitsTransfer | where JobState -eq "Transferred").count) / $((Get-BitsTransfer).count)) | Write-ValentiaVerboseDebug
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
                            default {
                                # NOT Async Transfer
                                try
                                {
                                    $ScriptToRun = "Start-BitsTransfer -Source $(($SourceFiles).fullname) -Destination $Destination -Credential $Credential -TransferType Download"
                                    foreach($SourceFile in $SourceFiles)
                                    {
                                        #Only start download for file.
                                        if (-not((Get-Item $SourceFile.fullname).Attributes -eq "Directory"))
                                        {
                                            Write-Warning ("Downloading {0} from {1} to {2}" -f ($SourceFile).fullname, $DeployMember, $Destination)
                                            Start-BitsTransfer -Source $(($SourceFile).fullname) -Destination $Destination -Credential $Credential -TransferType Download
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
            }
            else
            {
                Write-Warning ("{0} could find from {1}. Skip to next." -f $Source, $DeployGroups)
            }
        }

    
    ### End

        Write-Verbose "All transfer with BitsTransfer had been removed."

    }
    catch
    {

        $SuccessStatus += $false
        $ErrorMessageDetail += $_
        throw $_

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
            ErrorMessage = $($ErrorMessageDetail | where {$_ -ne $null} | sort -Unique)
        }

        # show result
        [PSCustomObject]$CommandResult

        # output result
        $CommandResult | ConvertTo-Json | Out-File -FilePath $LogPath -Encoding $valentia.fileEncode -Force -Width 1048

        # Cleanup valentia Environment
        Invoke-ValentiaClean

    }

}
