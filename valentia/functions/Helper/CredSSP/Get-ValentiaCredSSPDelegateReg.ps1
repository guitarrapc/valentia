#Requires -Version 3.0

#-- Public Functions for CredSSP Configuration --#

function Get-ValentiaCredSSPDelegateReg
{
    [CmdletBinding()]
    param
    (
        [Parameter(
            Position = 0,
            Mandatory = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Keys = $valentia.credssp.AllowFreshCredentialsWhenNTLMOnly.Key
    )

    $ErrorActionPreference = $valentia.errorPreference
    $path = (Split-Path $keys -Parent)
    $name = (Split-Path $keys -Leaf)
    Get-ItemProperty -Path $path `
    | %{
        [PSCustomObject]@{
            Name    = $name
            Value   = $_.$name
            Path    = $path
        }
    }
}