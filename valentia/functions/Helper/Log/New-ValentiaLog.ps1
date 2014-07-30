#Requires -Version 3.0

#-- Helper for valentia --#
#-- Log Settings -- #

<#
.SYNOPSIS 
Setup Valentia Log Folder

.DESCRIPTION
Check Valentia Log folder and return log full path

.NOTES
Author: guitarrapc
Created: 18/Sep/2013

.EXAMPLE
New-ValentiaLog -LogFolder c:\logs\deployment -LogFile "hoge.log"
--------------------------------------------
This is format sample.

.EXAMPLE
New-ValentiaLog
--------------------------------------------
As New-ValentiaLog have default value in parameter, you do not required to specify log information
#>
function New-ValentiaLog
{
    [CmdletBinding()]
    param
    (
        [Parameter(
            Position = 0, 
            Mandatory = 0,
            HelpMessage = "Path to LogFolder.")]
        [string]
        $LogFolder = $(Join-Path $valentia.Log.path (Get-Date).ToString("yyyyMMdd")),

        [Parameter(
            Position = 1, 
            Mandatory = 0,
            HelpMessage = "Name of LogFile.")]
        [string]
        $LogFile = "$($valentia.Log.name)_$((Get-Date).ToString("yyyyMMdd_HHmmss"))$($valentia.Log.extension)"
    )


    if (-not(Test-Path $LogFolder))
    {
        ("LogFolder not found creating {0}" -f $LogFolder) | Write-ValentiaVerboseDebug
        New-Item -Path $LogFolder -ItemType Directory > $null
    }

    try
    {
        "Defining LogFile full path." | Write-ValentiaVerboseDebug
        $valentia.Log.fullPath = Join-Path $LogFolder $LogFile
    }
    catch
    {
        $SuccessStatus += $false
        $ErrorMessageDetail += $_
        $ErrorCmdletName += ($MyInvocation.MyCommand).Name
        throw $_
    }

}
