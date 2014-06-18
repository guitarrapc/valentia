#Requires -Version 3.0

#-- Public Module Functions for Upload Listed Files --#

# uploadL

<#
.SYNOPSIS 
Use BITS Transfer to upload list files to remote server.

.DESCRIPTION
This function only support files listed in csv sat in upload context.
Make sure destination path format is not "c:\" but use "c$\" as UNC path.

.NOTES
Author: guitarrapc
Created: 13/July/2013


.EXAMPLE
uploadList -ListFile list.csv -DeployGroup DeployGroup.ps1
--------------------------------------------
upload sourthfile to destinationfile as define in csv for hosts written in DeployGroup.ps1.

#   # CSV SAMPLE
#
#    Source, Destination
#    C:\Deployment\Upload\Upload.txt,C$\hogehoge\Upload.txt
#    C:\Deployment\Upload\DownLoad.txt,C$\hogehoge\DownLoad.txt


.EXAMPLE
uploadList list.csv -DeployGroup DeployGroup.ps1
--------------------------------------------
upload sourthfile to destinationfile as define in csv for hosts written in DeployGroup.ps1. You can omit -listFile parameter.

#   # CSV SAMPLE
#
#    Source, Destination
#    C:\Deployment\Upload\Upload.txt,C$\hogehoge\Upload.txt
#    C:\Deployment\Upload\DownLoad.txt,C$\hogehoge\DownLoad.txt
#>
function Invoke-ValentiaUploadList
{
    [CmdletBinding()]
    param
    (
        [Parameter(
            Position = 0, 
            Mandatory,
            HelpMessage = "Input Clinet DestinationPath to save upload items.")]
        [string]
        $ListFile,

        [Parameter(
            Position = 1,
            Mandatory,
            HelpMessage = "Input target of deploy clients as [DeployGroup filename you sat at deploygroup Folder] or [ipaddress].")]
        [string]
        $DeployGroups,

        [Parameter(
            Position = 2,
            Mandatory = 0,
            HelpMessage = "Input DeployGroup Folder path if changed from default.")]
        [string]
        $DeployFolder = (Join-Path $Script:valentia.RootPath ([ValentiaBranchPath]::Deploygroup)),

        [Parameter(
            Position = 3,
            Mandatory = 0,
            HelpMessage = "Set this switch to execute command as Async (Job).")]
        [switch]
        $Async = $false
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
        $DeployMembers = Get-valentiaGroup -DeployFolder $DeployFolder -DeployGroup $DeployGroups
        
        # Set SourcePath to retrieve target File full path (default Upload folder of deployment)
        $SourceFolder = Join-Path $Script:valentia.RootPath ([ValentiaBranchPath]::Upload)

        if (-not(Test-Path $SourceFolder))
        {
            ("SourceFolder not found creating {0}" -f $SourceFolder) | Write-ValentiaVerboseDebug
            New-Item -Path $SourceFolder -ItemType Directory            
        }

        try
        {
            "Defining ListFile full path." | Write-ValentiaVerboseDebug
            $SourcePath = Join-Path $SourceFolder $ListFile -Resolve
        }
        catch
        {
            $SuccessStatus += $false
            $ErrorMessageDetail += $_
            throw $_
        }
        
        # Obtain List of File upload
        ("Retrive souce file list from {0} `n" -f $SourcePath) | Write-ValentiaVerboseDebug
        $List = Import-Csv $SourcePath -Delimiter "," 

        # Show Stopwatch for Begin section
        $TotalDuration = $TotalstopwatchSession.Elapsed.TotalSeconds
        Write-Verbose ("`t`tDuration Second for Begin Section: {0}" -f $TotalDuration)
        ""

    ### Process

        (" Uploading Files written in {0} to Target Computer : [{1}] `n" -f $SourcePath, $DeployMembers) | Write-ValentiaVerboseDebug

        # Stopwatch
        [decimal]$DurationTotal = 0

        foreach ($DeployMember in $DeployMembers){

            # Stopwatch
            $stopwatchSession = [System.Diagnostics.Stopwatch]::StartNew()
            
            #Create New List
            $NewList = $List | %{
                [PSCustomObject]@{
                    Source = $_.source
                    Destination = "\\" + $DeployMember + "\" + $($_.destination)
                }
            }
            
            try
            {
                # Run Start-BitsTransfer
                Write-Warning ("[{0}]: Uploading {1} to {2} ." -f $DeployMember ,"$($NewList.Source)", "$($NewList.Destination)")
                Write-Verbose ("ListFile : {0}" -f $SourcePath)
                Write-Verbose ("Aysnc : {0}" -f $Async)

                if ($Async)
                {
                    #Command Detail
                    $ScriptToRun = '$NewList | Start-BitsTransfer -Credential $Credential -Async'

                    # Run Start-BitsTransfer retrieving files from List csv with Async switch
                    ("Running Async uploadL to '{0}'" -f $DeployMember) | Write-ValentiaVerboseDebug
                    $BitsJob = $NewList | Start-BitsTransfer -Credential $Credential -Async

                    # Monitoring Bits Transfer States complete
                    $Sleepms = 10
                    while (((Get-BitsTransfer).JobState -contains "Transferring") -or ((Get-BitsTransfer).JobState -contains "Connecting") -or ((Get-BitsTransfer).JobState -contains "Queued")) `
                    {
                        ("Current Job States was '{0}', waiting for '{1}' ms '{2}'" -f "$((Get-BitsTransfer).JobState | sort -Unique)", $Sleepms, (((Get-BitsTransfer | where JobState -eq "Transferred").count) / $((Get-BitsTransfer).count))) | Write-ValentiaVerboseDebug
                        sleep -Milliseconds $Sleepms
                    }

                    # Send Complete message to make file from ****.Tmp
                    ("Completing Async uploadL to '{0}'" -f $DeployMember) | Write-ValentiaVerboseDebug
                    # Retrieve all files when completed
                    Get-BitsTransfer | Complete-BitsTransfer

                }
                else
                {
                    #Command Detail
                    $ScriptToRun = "$NewList | Start-BitsTransfer -Credential $Credential"

                    # Run Start-BitsTransfer retrieving files from List csv
                    ("Running Sync uploadL to {0}" -f $DeployMember) | Write-ValentiaVerboseDebug
                    $NewList | Start-BitsTransfer -Credential $Credential
                }
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
                "Delete all not compelte job" | Write-ValentiaVerboseDebug
                Get-BitsTransfer | Remove-BitsTransfer

                # Stopwatch
                $Duration = $stopwatchSession.Elapsed.TotalSeconds
                Write-Verbose ("Session duration Second : {0}" -f $Duration)
                ""
            }
        }

    ### End

    }
    catch
    {
        $SuccessStatus += $false
        $ErrorMessageDetail += $_
        $_
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
