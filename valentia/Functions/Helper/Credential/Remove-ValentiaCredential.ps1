#Requires -Version 3.0

function Remove-ValentiaCredential
{
    [OutputType([void])]
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
 
    [Valentia.CS.CredentialManager]::Remove($TargetName, $Type);
}