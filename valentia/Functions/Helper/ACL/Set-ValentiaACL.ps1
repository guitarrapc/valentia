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
Add FullControl to the c:\Deployment for user "Users", means no Computer/Domain user name checking.

.EXAMPLE
Set-ValentiaACL -Path c:\Deployment -Account contoso\John -Rights Modify -Ensure Present -Access Allow -Inherit $false -Recurse $false
--------------------------------------------
Add FullControl to the c:\Deployment for user "BuiltIn\Users", means strict user name checking.

.ExternalHelp "https://github.com/guitarrapc/DSCResources/tree/master/Custom/gACLResource"
#>
function Set-ValentiaACL
{
    [CmdletBinding()]
    param
    (
        [Parameter(mandatory = $true, position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]$Path,

        [Parameter(mandatory = $true, position = 1)]
        [ValidateNotNullOrEmpty()]
        [String]$Account,

        [Parameter(mandatory = $false, position = 2)]
        [ValidateNotNullOrEmpty()]
        [System.Security.AccessControl.FileSystemRights]$Rights = "ReadAndExecute",

        [Parameter(mandatory = $false, position = 3)]
        [ValidateSet("Present", "Absent")]
        [ValidateNotNullOrEmpty()]
        [String]$Ensure = "Present",
        
        [Parameter(mandatory = $false, position = 4)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Allow", "Deny")]
        [System.Security.AccessControl.AccessControlType]$Access = "Allow",

        [Parameter(mandatory = $false, position = 5)]
        [Bool]$Inherit = $false,

        [Parameter(mandatory = $false, position = 6)]
        [Bool]$Recurse = $false,

        [Parameter(mandatory = $false, position = 7)]
        [Bool]$Strict = $false
    )

    $desiredRule = GetDesiredRule -Path $Path -Account $Account -Rights $Rights -Access $Access -Inherit $Inherit -Recurse $Recurse
    $currentACL = (Get-Item $Path).GetAccessControl("Access")
    $currentRules = $currentACL.GetAccessRules($true, $true, [System.Security.Principal.NTAccount])
    $match = IsDesiredRuleAndCurrentRuleSame -DesiredRule $desiredRule -CurrentRules $currentRules -Strict $Strict

    if ($Ensure -eq "Present")
    {
        $CurrentACL.AddAccessRule($DesiredRule)
        $CurrentACL | Set-Acl -Path $Path 
    }
    elseif ($Ensure -eq "Absent")
    {
        $CurrentACL.RemoveAccessRule($DesiredRule) > $null
        $CurrentACL | Set-Acl -Path $Path 
    }
}