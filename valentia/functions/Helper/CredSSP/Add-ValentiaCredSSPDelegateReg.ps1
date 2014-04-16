#Requires -Version 3.0

#-- Public Functions for CredSSP Configuration --#

function Add-ValentiaCredSSPDelegateReg
{
    [CmdletBinding()]
    param
    (
        [Parameter(
            Position = 1,
            Mandatory = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Keys = $valentia.credssp.AllowFreshCredentialsWhenNTLMOnly.Key
    )

    $ErrorActionPreference = $valentia.errorPreference
    Set-StrictMode -Version latest

    $param = @{
        Path  = (Split-Path $keys -Parent)
        Name  = (Split-Path $keys -Leaf)
        Value = 1
        Force = $true
    }

    $result = Get-ValentiaCredSSPDelegateReg -Keys $Keys
    if ($result.Value -ne 1)
    {
        Set-ItemProperty @param -PassThru
    }
    elseif ($null -eq $result)
    {
        New-ItemProperty @param
    }
}