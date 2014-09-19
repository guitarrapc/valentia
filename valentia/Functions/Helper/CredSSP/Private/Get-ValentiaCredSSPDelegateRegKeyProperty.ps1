#Requires -Version 3.0

#-- Public Functions for CredSSP Configuration --#

function Get-ValentiaCredSSPDelegateRegKeyProperty
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, Mandatory = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Keys = $valentia.credssp.AllowFreshCredentialsWhenNTLMOnly.Key
    )

    $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
    Set-StrictMode -Version latest

    $regProperty = Get-ItemProperty -Path $keys
    if ($regProperty)
    {
        $regProperty `
        | Get-Member -MemberType NoteProperty `
        | where Name -Match "\d+" `
        | %{
            $name = $_.Name
            [PSCustomObject]@{
                Key   = $name
                Value = $regProperty.$name
                path  = $keys
            }
        }
    }
    else
    {
        [PSCustomObject]@{
            Key   = ""
            Value = ""
            path  = $Keys
        }
    }
}