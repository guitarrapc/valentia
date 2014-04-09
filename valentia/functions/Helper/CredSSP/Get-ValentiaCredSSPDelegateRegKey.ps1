#Requires -Version 3.0

#-- Public Functions for CredSSP Configuration --#

function Get-ValentiaCredSSPDelegateRegKey
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
        $Keys = $valentia.credssp.AllowFreshCredentialsWhenNTLMOnly.Key
    )

    $ErrorActionPreference = $valentia.errorPreference

    $keys `
    | % {
        $regProperty = Get-ItemProperty -Path $_
        if ($regProperty)
        {
            $regProperty `
            | Get-Member -MemberType NoteProperty `
            | where Name -Match "\d+" `
            | %{
                $name = $_.Name
                [PSCustomObject]@{
                    Key = $name
                    Value   = $regProperty.$name
                    pspath  = $regProperty.PSPath
                }
            }
        }
    }
}