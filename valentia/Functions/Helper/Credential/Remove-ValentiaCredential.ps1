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
        [ValentiaWindowsCredentialManagerType]$Type = [ValentiaWindowsCredentialManagerType]::Generic
    )
 
    try
    {
        $private:nCredPtr= New-Object IntPtr
        if ([Valentia.CS.NativeMethods]::CredDelete($TargetName, $Type.value__, 0))
        {
        }
        else
        {
            throw "No credentials found in Windows Credential Manager for TargetName: '{0}' with Type '{1}'" -f $TargetName, $Type
        }
    }
    catch
    {
        throw $_
    }
}