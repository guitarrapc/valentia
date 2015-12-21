#Requires -Version 3.0

#-- Public Functions for CredSSP Configuration --#

function Get-ValentiaCredSSPDelegateReg
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Keys = $valentia.credssp.AllowFreshCredentialsWhenNTLMOnly.Key
    )

    $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
    Set-StrictMode -Version latest

    $path = (Split-Path $keys -Parent)
    $name = (Split-Path $keys -Leaf)
    Get-ItemProperty -Path $path `
    | %{
        $hashtable = @{
            Name    = $name
            Path    = $path
        }

        if ($_ | Get-Member | where MemberType -eq NoteProperty | where Name -eq $name)
        {
            $hashtable.Add("Value", $_.$name)
        }
        else
        {
            $hashtable.Add("Value", $null)
        }
        
        [PSCustomObject]$hashtable
    }
}