#Requires -Version 3.0

function Get-ValentiaCredential
{
    [OutputType([PSCredential])]
    [CmdletBinding()]
    param
    (
        [Parameter(mandatory = $false, position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$TargetName = $valentia.name,

        [Parameter(mandatory = $false, position = 1)]
        [ValidateNotNullOrEmpty()]
        [Valentia.CS.CredType]$Type = [Valentia.CS.CredType]::Generic,

        [Parameter(mandatory = $false, position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]$AsUserName = ""
    )
    
    return [Valentia.CS.CredentialManager]::Read($TargetName, $Type, $AsUserName);
}