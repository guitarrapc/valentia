#Requires -Version 3.0

#-- Public Functions for CredSSP Configuration --#

function Add-ValentiaCredSSPDelegateRegKey
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

    $param = @{
        Path  = (Split-Path $keys -Parent)
        Name  = (Split-Path $keys -Leaf)
        Force = $true
    }
    $result = Get-ValentiaCredSSPDelegateRegKey -Keys $Keys
    if ($result -eq $false)
    {
        New-Item @param
    }
}