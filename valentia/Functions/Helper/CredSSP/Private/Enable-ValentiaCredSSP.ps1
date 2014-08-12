#Requires -Version 3.0

#-- Public Functions for CredSSP Configuration --#

function Enable-ValentiaCredSSP
{
    [CmdletBinding()]
    param
    (
        [Parameter(
            Position = 0,
            Mandatory = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $TrustedHosts = $valentia.wsman.TrustedHosts
    )

    $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
    Set-StrictMode -Version latest

    try
    {
        Enable-WSManCredSSP -Role Server -Force
        Enable-WSManCredSSP -Role Client -DelegateComputer $TrustedHosts -Force
    }
    catch
    {
        # Unfortunately you need to repeat cpmmand again to enable Client Role.
        Enable-WSManCredSSP -Role Client -DelegateComputer $TrustedHosts -Force
    }
    finally
    {
        Get-WSManCredSSP
    }
}