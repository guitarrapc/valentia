#Requires -Version 3.0

<#
.SYNOPSIS 
Set ACL from selected source path.

.DESCRIPTION
You can Set ACL information to selected source path.
This is same logic as gACLResource. 

.NOTES
Author: guitarrapc
Created: 3/Sep/2014

.EXAMPLE
Set-ValentiaACL -Path c:\Deployment -Account Users -Rights Modify -Ensure Present -Access Allow -Inherit $false -Recurse $false
--------------------------------------------
Add FullControl to the c:\Deployment for user "BuiltIn\Users".

.ExternalHelp "https://github.com/guitarrapc/DSCResources/tree/master/Custom/gACLResource"
#>
function Set-ValentiaACL
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = 1, position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Path,

        [Parameter(Mandatory = 1, position = 1)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Account,

        [Parameter(Mandatory = 0, position = 2)]
        [ValidateNotNullOrEmpty()]
        [System.Security.AccessControl.FileSystemRights]
        $Rights = "ReadAndExecute",

        [Parameter(Mandatory = 0, position = 3)]
        [ValidateSet("Present", "Absent")]
        [ValidateNotNullOrEmpty()]
        [String]
        $Ensure = "Present",
        
        [Parameter(Mandatory = 0, position = 4)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Allow", "Deny")]
        [System.Security.AccessControl.AccessControlType]
        $Access = "Allow",

        [Parameter(Mandatory = 0, position = 5)]
        [Bool]
        $Inherit = $false,

        [Parameter(Mandatory = 0, position = 6)]
        [Bool]
        $Recurse = $false
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

    $DesiredRule = New-Object System.Security.AccessControl.FileSystemAccessRule($Account, $Rights, $InheritFlag, "None", $Access)
    $CurrentACL = (Get-Item $Path).GetAccessControl("Access")
    $CurrentRules = $CurrentACL.GetAccessRules($true, $true, [System.Security.Principal.NTAccount])
    $Match = $CurrentRules `
    | where {($DesiredRule.IdentityReference -eq $_.IdentityReference) `
        -and ($DesiredRule.FileSystemRights -eq $_.FileSystemRights) `
        -and ($DesiredRule.AccessControlType -eq $_.AccessControlType) `
        -and ($Inherit -eq $_.InheritanceFlags )
    }

    if ($Ensure -eq "Present")
    {
        if ($null -eq $Match)
        {
            $CurrentACL.AddAccessRule($DesiredRule)
            $CurrentACL | Set-Acl -Path $Path 
        }
    }
    elseif ($Ensure -eq "Absent")
    {
        $Match | % {$CurrentACL.RemoveAccessRule($_)} > $null
        $CurrentACL | Set-Acl -Path $Path 
    }
}