#Requires -Version 3.0

function GetDesiredRule
{
    [OutputType([System.Security.AccessControl.FileSystemAccessRule])]
    [CmdletBinding()]
    param
    (
        [Parameter(mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$Path,

        [Parameter(mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$Account,

        [Parameter(mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Security.AccessControl.FileSystemRights]$Rights = "ReadAndExecute",

        [Parameter(mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Security.AccessControl.AccessControlType]$Access = "Allow",

        [Parameter(mandatory = $false)]
        [Bool]$Inherit = $false,

        [Parameter(mandatory = $false)]
        [Bool]$Recurse = $false
    )

    $InheritFlag = if ($Inherit)
    {
        "{0}, {1}" -f [System.Security.AccessControl.InheritanceFlags]::ContainerInherit, [System.Security.AccessControl.InheritanceFlags]::ObjectInherit
    }
    elseif ($Recurse)
    {
        "{0}, {1}" -f [System.Security.AccessControl.InheritanceFlags]::ContainerInherit, [System.Security.AccessControl.InheritanceFlags]::ObjectInherit
    }
    else
    {
        [System.Security.AccessControl.InheritanceFlags]::None
    }

    $desiredRule = New-Object System.Security.AccessControl.FileSystemAccessRule($Account, $Rights, $InheritFlag, "None", $Access)
    return $desiredRule
}
