#Requires -Version 3.0

#-- Prerequisite OS Setting Module Functions --#

<#
.SYNOPSIS 
Disable EnhancedIESecutiry for Internet Explorer

.DESCRIPTION
Change registry to disable EnhancedIESecutiry.
It will only work for [Windows Server] not for Workstation, and [Windows Server 2008 R2] and higer.

.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
Disable-ValentiaEnhancedIESecutiry
--------------------------------------------
Disable IEEnhanced security.
#>
function Disable-ValentiaEnhancedIESecutiry
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, mandatory = $false, HelpMessage = "Registry key for Admin.")]
        [string]$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}",
    
        [Parameter(Position = 0, mandatory = $false, HelpMessage = "Registry key for User.")]
        [string]$UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    )

    $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
    Set-StrictMode -Version latest

    # get os version, Windows 7 will be "6 1 0 0"
    $osversion = [Environment]::OSVersion.Version

    # Higher than $valentia.supportWindows
    $minimumversion = New-Object 'Version' $valentia.supportWindows

    # check osversion higher than valentia support version
    if ($osversion -ge $minimumversion)
    {
        if (Test-Path $AdminKey)
        {
            if ((Get-ItemProperty -Path $AdminKey -Name "IsInstalled").IsInstalled -eq "1")
            {
                Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
                $IsstatusChanged = $true
            }
            else
            {
                $IsstatusChanged = $false
            }
        }
        else
        {
            $IsstatusChanged = $false
        }

        if (Test-Path $UserKey)
        {
            if ((Get-ItemProperty -Path $UserKey -Name "IsInstalled").IsInstalled -eq "1")
            {
                Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
                $IsstatusChanged = $true
            }
            else
            {
                $IsstatusChanged = $false
            }
        }
        else
        {
            $IsstatusChanged = $false
        }

        if ($IsstatusChanged)
        {
            # Stop Internet Exploer if launch
            "IE Enhanced Security Configuration (ESC) has been disabled. Checking IE to stop process." | Write-ValentiaVerboseDebug
            Get-Process | where Name -eq "iexplore" | Stop-Process -Confirm
        }
        else
        {
            "IE Enhanced Security Configuration (ESC) had already been disabled. Nothing will do." | Write-ValentiaVerboseDebug
        }
    }
    else
    {
        Write-Warning -Message ("Your Operating System '{0}', Version:'{1}' was lower than valentia supported version '{2}'." -f `
            (Get-CimInstance -class Win32_OperatingSystem).Caption,
            $osversion,
            $minimumversion)
    }
}
