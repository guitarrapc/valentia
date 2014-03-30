#Requires -Version 3.0

#-- Public Functions for WSMan Parameter Configuration --#

function Enable-ValentiaWsManCredSSP
{
    [CmdletBinding()]
    param
    (
        [Parameter(
            Position = 0,
            Mandatory = 1)]
        [string]
        $TrustedHosts
    )

    $ErrorActionPreference = $valentia.errorPreference

    try
    {
        Disable-WSManCredSSP -Role Client
        Enable-WSManCredSSP -Role Client -DelegateComputer $TrustedHosts -Force
    }
    catch
    {
        WSManCredSSP -Role Client -DelegateComputer $TrustedHosts -Force
    }
    finally
    {
        $regKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Credssp\PolicyDefaults\AllowFreshCredentialsDomain"
        Set-ItemProperty $regKey -Name WSMan -Value "WSMAN/*"
    }
}