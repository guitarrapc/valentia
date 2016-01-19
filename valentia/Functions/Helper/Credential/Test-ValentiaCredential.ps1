#Requires -Version 3.0

function Test-ValentiaCredential
{
    [CmdletBinding()]
    param
    (
        [Parameter(mandatory = $false, position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$TargetName = $valentia.name,

        [Parameter(mandatory = $false, position = 1)]
        [ValidateNotNullOrEmpty()]
        [ValentiaWindowsCredentialManagerType]$Type = [ValentiaWindowsCredentialManagerType]::Generic
    )
 
    try
    {
        $result = Get-ValentiaCredential -TargetName $targetName
        return $true;
    }
    catch
    {
        return $false;
    }
}