﻿#Requires -Version 3.0

#-- Public Module Functions for Sync Files or Directories--#

# Sync

<#
.SYNOPSIS 
Use fastcopy.exe to Sync Folder for Diff folder/files not consider Diff from remote server.

.DESCRIPTION
You must install fastcopy.exe to use this function.

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
        [Parameter(
            Position = 0,
            Mandatory,
            HelpMessage = "Input Deploy Server Source Folder Sync to Client PC.")]
        [string]
        $SourceFolder, 

        [Parameter(
            Position = 1,
            Mandatory,
            HelpMessage = "Input Client Destination Folder Sync with Desploy Server.")]
        [String]
        $DestinationFolder,

        [Parameter(
            Position = 2,
            Mandatory,
            HelpMessage = "Input target of deploy clients as [DeployGroup filename you sat at deploygroup Folder] or [ipaddress].")]
        [string]
        $DeployGroups,

        [Parameter(
            Position = 3,
            Mandatory = 0,
            HelpMessage = "Input DeployGroup Folder path if changed.")]
        [string]
        $DeployFolder = (Join-Path $Script:valentia.RootPath ([ValentiaBranchPath]::Deploygroup)),

        [Parameter(
            Position = 4,
            Mandatory = 0,
            HelpMessage = "Return success result even if there are error.")]
        [bool]
        $SkipException = $false,

        [Parameter(
            Position = 5,
            Mandatory = 0,
            HelpMessage = "Input fastCopy.exe location folder if changed.")]
        [string]
        $FastCopyFolder = $valentia.fastcopy.folder,
        
        [Parameter(
            Position = 6,
            Mandatory = 0,
            HelpMessage = "Input fastCopy.exe name if changed.")]
        [string]
        $FastcopyExe =  $valentia.fastcopy.exe
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
    
        # Check FastCopy.exe path
        "Checking FastCopy Folder is exist or not." | Write-ValentiaVerboseDebug
        if (-not(Test-Path $FastCopyFolder))
        {
            New-Item -Path $FastCopyFolder -ItemType Directory
        }

        # Set FastCopy.exe path
        Write-Verbose "Set FastCopy.exe path."
        $FastCopy = Join-Path $FastCopyFolder $FastcopyExe

        # Check SourceFolder Exist or not
        if (-not(Test-Path $SourceFolder))
        {
            $SuccessStatus += $false
            $ErrorMessageDetail += "SourceFolder [ $SourceFolder ] not found exeptions! exit job."
            throw "SourceFolder [ {0} ] not found exeptions! exit job." -f $SourceFolder
        }

        # Obtain DeployMember IP or Hosts for FastCopy
        "Get hostaddresses to connect." | Write-ValentiaVerboseDebug
        $DeployMembers = Get-valentiaGroup -DeployFolder $DeployFolder -DeployGroup $DeployGroups
        
        # Parse Network Destination Path
        ("Parsing Network Destination Path {0} as :\ should change to $." -f $DestinationFolder) | Write-ValentiaVerboseDebug
        $DestinationPath = "$DestinationFolder".Replace(":","$")

        # Safety exit for root drive
        if ($SourceFolder.Length -ge 3)
        {
            Write-Verbose ("SourceFolder[-2]`t:`t$($SourceFolder[-2])")
            Write-Verbose ("SourceFolder[-1]`t:`t$($SourceFolder[-1])")
            if (($SourceFolder[-2] + $SourceFolder[-1]) -in (":\",":/"))
            {
                $SuccessStatus += $false
                $ErrorMessageDetail += ("SourceFolder path was Root Drive [ {0} ] exception! Exist for safety." -f $SourceFolder)

                throw ("SourceFolder path was Root Drive [ {0} ] exception! Exist for safety." -f $SourceFolder)
            }
        }

        # Show Stopwatch for Begin section
        $TotalDuration = $TotalstopwatchSession.Elapsed.TotalSeconds
        Write-Verbose ("`t`tDuration Second for Begin Section: {0}" -f $TotalDuration)
        ""

    ### Process

        Write-Warning "Starting Sync Below files"
        Write-Verbose (" Syncing {0} to Target Computer : [{1}] {2} `n" -f $SourceFolder, $DeployMembers, $DestinationFolder)
        (Get-ChildItem $SourceFolder).FullName

        # Stopwatch
        [decimal]$DurationTotal = 0

        foreach ($DeployMember in $DeployMembers)
        {
            # Stopwatch
            $stopwatchSession = [System.Diagnostics.Stopwatch]::StartNew()

            # Create Destination
            $Destination = Join-Path "\\" $(Join-Path "$DeployMember" "$DestinationPath")

            # Set FastCopy.exe Argument for Sync
            $FastCopyArgument = "/cmd=sync /bufsize=512 /speed=full /wipe_del=FALSE /acl /stream /reparse /force_close /estimate /error_stop=FALSE /log=True /logfile=""$LogPath"" ""$SourceFolder"" /to=""$Destination"""

            # Run FastCopy
            Write-Warning ("[{0}]:Uploading {1} to {2}." -f $DeployMember ,$SourceFolder, $Destination)
            Write-Verbose ("FastCopy : {0}" -f $FastCopy)
            Write-Verbose ("FastCopyArgument : {0}" -f $FastCopyArgument)

            if (Ping-ValentiaGroupAsync -HostNameOrAddresses $DeployMember)
            {
                try
                {
                    'Command : Start-Process $FastCopy -ArgumentList $FastCopyArgument -Wait -PassThru -Credential $Credential' | Write-ValentiaVerboseDebug
                    $Result = Start-Process $FastCopy -ArgumentList $FastCopyArgument -Wait -PassThru -Credential $Credential
                }
                catch
                {
                    Write-Error $_
                    $SuccessStatus += $false
                    $ErrorMessageDetail += $_ 
                }
            }
            else
            {
                Write-Error ("Target Host {0} unreachable. Check DeployGroup file [ {1} ] again" -f $DeployMember, $DeployGroups)
                $SuccessStatus += $false
                $ErrorMessageDetail += ("Target Host {0} unreachable. Check DeployGroup file [ {1} ] again" -f $DeployMember, $DeployGroups)
            }

            # Stopwatch
            $Duration = $stopwatchSession.Elapsed.TotalSeconds
            Write-Verbose ("Session duration Second : {0}" -f $Duration)
            ""
            $DurationTotal += $Duration
        }

    ### End
   
        "All Sync job complete." | Write-ValentiaVerboseDebug
        if (Test-Path $LogPath)
        {
            if (-not((Select-String -Path $LogPath -Pattern "No Errors").count -ge $DeployMembers.count))
            {
                $SuccessStatus += $false
                $ErrorMessageDetail += ("One or more host was reachable with ping, but not authentiacate to DestinationFolder [ {0} ]" -f $DestinationFolder)
                Write-Error ("One or more host was reachable with ping, but not authentiacate to DestinationFolder [ {0} ]" -f $DestinationFolder)
            }
        }
        else
        {
            $SuccessStatus += $false
            $ErrorMessageDetail += ("None of the host was reachable with ping with DestinationFolder [ {0} ]" -f $DestinationFolder)
            Write-Error ("None of the host was reachable with ping with DestinationFolder [ {0} ]" -f $DestinationFolder)
        }

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
        # Show Stopwatch for Total section
        $TotalDuration += $TotalstopwatchSession.Elapsed.TotalSeconds
        Write-Verbose ("`t`tTotal duration Second`t: {0}" -f $TotalDuration)

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
            ScriptBlock = "Start-Process $FastCopy -ArgumentList $FastCopyArgument -Wait"
            DeployGroup = "$DeployGroups"
            TargetHosCount = $($DeployMembers.count)
            TargetHosts = "$DeployMembers"
            Result = $result
            SkipException  = $SkipException
            ErrorMessage = $($ErrorMessageDetail | where {$_ -ne $null} | sort -Unique)
        }

        # show result
        [PSCustomObject]$CommandResult

        # output result
        $CommandResult | ConvertTo-Json | Out-File -FilePath $LogPath -Encoding $valentia.fileEncode -Force -Width 1048 -Append

        # Cleanup valentia Environment
        Invoke-ValentiaClean
    }

}
