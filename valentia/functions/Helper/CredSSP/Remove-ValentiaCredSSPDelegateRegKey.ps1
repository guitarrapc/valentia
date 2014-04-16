#Requires -Version 3.0

#-- Public Functions for CredSSP Configuration --#

function Remove-ValentiaCredSSPDelegateRegKey
{
    [CmdletBinding()]
    param
    (
        [Parameter(
            Position = 0,
            Mandatory = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $TrustedHosts = $valentia.wsman.TrustedHosts,

        [Parameter(
            Position = 1,
            Mandatory = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Keys = $valentia.credssp.AllowFreshCredentialsWhenNTLMOnly.Key,

        [Parameter(
            Position = 2,
            Mandatory = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $regValue = $valentia.credssp.AllowFreshCredentialsWhenNTLMOnly.Value
    )

    $ErrorActionPreference = $valentia.errorPreference
    Set-StrictMode -Version latest

    $result = Get-ValentiaCredSSPDelegateRegKey -TrustedHosts $TrustedHosts -Keys $Keys
    if ($result.Value -contains $regValue)
    {
        $result | %{Remove-ItemProperty -Path $_.pspath -Name $_.Key -Force}
    }
}