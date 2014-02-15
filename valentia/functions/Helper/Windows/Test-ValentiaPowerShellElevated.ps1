#Requires -Version 3.0

#-- Helper function --#

#-- Check Current PowerShell session is elevated or not --#

function Test-ValentiaPowerShellElevated
{

<#
.SYNOPSIS
    Retrieve elavated status of PowerShell Console.

.DESCRIPTION
    Test-ValentiaPowerShellElevated will check shell was elevated is required for some operations access to system folder, files and objects.
      
.NOTES
    Author: guitarrapc
    Date:   June 17, 2013

.OUTPUTS
    bool

.EXAMPLE
    C:\PS> Test-ValentiaPowerShellElevated

        true

.EXAMPLE
    C:\PS> Test-ValentiaPowerShellElevated

        false
        
#>


    [CmdletBinding()]
    param
    (
    )

    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    return (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}
