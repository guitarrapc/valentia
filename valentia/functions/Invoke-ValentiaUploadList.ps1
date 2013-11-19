#Requires -Version 3.0

#-- Public Module Functions for Upload Listed Files --#

# uploadL
function Invoke-ValentiaUploadList
{

<#
.SYNOPSIS 
Use BITS Transfer to upload list files to remote server.

.DESCRIPTION
This function only support files listed in csv sat in upload context.
Make sure destination path format is not "c:\" but use "c$\" as UNC path.

.NOTES
Author: Ikiru Yoshizaki
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
        $DeployFolder = (Join-Path $Script:valentia.RootPath $Script:valentia.BranchFolder.DeployGroup),

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
            
        $ErrorActionPreference = $valentia.errorPreference

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
            Write-Verbose $valeWarningMessages.warn_import_configuration
            Import-valentiaConfigration -Verbose

            # Import default Modules
            Write-Verbose $valeWarningMessages.warn_import_modules
            Import-valentiaModules -Verbose
        }
        else
        {
            Import-valentiaConfigration
            Import-valentiaModules
        }


        # Log Setting
        $LogPath = New-ValentiaLog


        # Import Bits Transfer Module
        try
        {
            Write-Verbose "Importing BitsTransfer Module to ready File Transfer."
            Import-Module BitsTransfer
        }
        catch
        {
            $SuccessStatus += $false
            $ErrorMessageDetail += $_
            throw $_
        }


        # Obtain Remote Login Credential
        try
        {
            $Credential = Get-ValentiaCredential
            $SuccessStatus += $true
        }
        catch
        {
            Write-Error $_
            $SuccessStatus += $false
        }


        # Obtain DeployMember IP or Hosts for BITsTransfer
        $DeployMembers = Get-valentiaGroup -DeployFolder $DeployFolder -DeployGroup $DeployGroups
        Write-Verbose ("Connecting to Target Computer : [{0}] `n" -f $DeployMembers)
        
        if ($DeployMembers.SuccessStatus -eq $false)
        {
            $SuccessStatus += $DeployMembers.SuccessStatus
            $ErrorMessageDetail += $DeployMembers.ErrorMessageDetail
        }        



        # Set SourcePath to retrieve target File full path (default Upload folder of deployment)
        $SourceFolder = Join-Path $Script:valentia.RootPath $Script:valentia.BranchFolder.Upload

        if (-not(Test-Path $SourceFolder))
        {
            Write-Verbose ("SourceFolder not found creating {0}" -f $SourceFolder)
            New-Item -Path $SourceFolder -ItemType Directory            
        }

        try
        {
            Write-Verbose "Defining ListFile full path."
            $SourcePath = Join-Path $SourceFolder $ListFile
            Get-Item $SourcePath > $null
        }
        catch
        {
            $SuccessStatus += $false
            $ErrorMessageDetail += $_
            throw $_
        }


        # Obtain List of File upload
        Write-Verbose ("Retrive souce file list from {0} `n" -f $SourcePath)
        $List = Import-Csv $SourcePath -Delimiter "," 

        # Show Stopwatch for Begin section
        $TotalDuration = $TotalstopwatchSession.Elapsed.TotalSeconds
        Write-Verbose ("`t`tDuration Second for Begin Section: {0}" -f $TotalDuration)
        ""


    ### Process


        Write-Verbose (" Uploading Files written in {0} to Target Computer : [{1}] `n" -f $SourcePath, $DeployMembers)

        # Stopwatch
        [decimal]$DurationTotal = 0

        Write-Verbose ("Starting Upload {0} ." -f $List.Source)
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
                Write-Verbose ("Uploading {0} to {1} ." -f "$($NewList.Source)", "$($NewList.Destination)")
                Write-Verbose ("ListFile : {0}" -f $SourcePath)
                Write-Verbose ("SourcePath : {0}" -f "$($NewList.Source)")
                Write-Verbose ("DestinationPath : {0}" -f "$($List.Destination)")
                Write-Verbose ("DeployMember : {0}" -f $DeployMember)
                Write-Verbose ("Aysnc : {0}" -f $Async)

                if ($Async)
                {
                    #Command Detail
                    Write-Verbose 'Command : $NewList | Start-BitsTransfer -Credential $Credebtial -Async'
                    $ScriptToRun = '$NewList | Start-BitsTransfer -Credential $Credential -Async'

                    # Run Start-BitsTransfer retrieving files from List csv with Async switch
                    Write-Warning ("Running Async uploadL to '{0}'" -f $DeployMember)
                    $BitsJob = $NewList | Start-BitsTransfer -Credential $Credential -Async

                    # Monitoring Bits Transfer States complete
                    $Sleepms = 10
                    while (((Get-BitsTransfer).JobState -contains "Transferring") -or ((Get-BitsTransfer).JobState -contains "Connecting") -or ((Get-BitsTransfer).JobState -contains "Queued")) `
                    {
                        Write-Warning ("Current Job States was '{0}', waiting for '{1}' ms '{2}'" -f "$((Get-BitsTransfer).JobState | sort -Unique)", $Sleepms, (((Get-BitsTransfer | where JobState -eq "Transferred").count) / $((Get-BitsTransfer).count)))
                        sleep -Milliseconds $Sleepms
                    }

                    # Send Complete message to make file from ****.Tmp
                    Write-Warning ("Completing Async uploadL to '{0}'" -f $DeployMember)
                    # Retrieve all files when completed
                    Get-BitsTransfer | Complete-BitsTransfer

                }
                else
                {
                    #Command Detail
                    Write-Verbose 'Command : $NewList | Start-BitsTransfer -Credential $Credebtial'
                    $ScriptToRun = "$NewList | Start-BitsTransfer -Credential $Credential"

                    # Run Start-BitsTransfer retrieving files from List csv
                    Write-Warning ("Running Sync uploadL to {0}" -f $DeployMember)
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
                # Delete all not compelte job
                Get-BitsTransfer | Remove-BitsTransfer

                # Stopwatch
                $Duration = $stopwatchSession.Elapsed.TotalSeconds
                Write-Verbose ("Session duration Second : {0}" -f $Duration)

                # Add current session to Total
                $DurationTotal += $Duration
                ""
            }
        }


    ### End


        Write-Verbose "All transfer with BitsTransfer had been removed."

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
