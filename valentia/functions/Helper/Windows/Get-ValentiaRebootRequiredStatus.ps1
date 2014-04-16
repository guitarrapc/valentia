#Requires -Version 3.0

#-- Prerequisite OS Setting Module Functions --#

<#
.SYNOPSIS 
Get reboot require status for client

.DESCRIPTION
When Windows Update or Change Hostname event is done, it will requires reboot to take change effect.
You can obtain reboot required status with this cmdlet.

.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
Get-ValentiaRebootRequiredStatus
--------------------------------------------
Obtain reboot required status.
#>
function Get-ValentiaRebootRequiredStatus
{
    [CmdletBinding()]
    param
    (
    )

    begin
    {
        $ErrorActionPreference = $valentia.errorPreference
        Set-StrictMode -Version latest

        $WindowsUpdateRebootStatus = $false
        $FileRenameRebootStatus = $false
        $WindowsUpdateRebootPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
        $FileRenameRebootPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
    }

    process
    {
        if (Test-Path $WindowsUpdateRebootPath)
        {
            $WindowsUpdateRebootStatus = $true
        }


        if (Get-ItemProperty -Path $FileRenameRebootPath | Get-Member -MemberType NoteProperty | where Name -eq "PendingFileRenameOperations")
        {
            $FileRenameRebootStatus = $True
        }

        $Result = [PSCustomObject]@{
            ComputerName = [Net.DNS]::GetHostName()
            PendingWindowsUpdateReboot= $WindowsUpdateRebootStatus
            PendingFileRenameReboot = $FileRenameRebootStatus
        }

    }

    end
    {
        return $Result
    }

}