#Requires -Version 3.0

function Test-ValentiaCredential
{
    [OutputType([bool])]
    [CmdletBinding()]
    param
    (
        [Parameter(mandatory = $false, position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$TargetName = $valentia.name,

        [Parameter(mandatory = $false, position = 1)]
        [ValidateNotNullOrEmpty()]
        [Valentia.CS.CredType]$Type = [Valentia.CS.CredType]::Generic
    )
 
    [Valentia.CS.CredentialManager]::Exists($TargetName, $Type);
}