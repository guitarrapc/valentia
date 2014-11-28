#Requires -Version 3.0

<#
.SYNOPSIS 
Test ACL from selected source path.

.DESCRIPTION
You can Test ACL information to selected source path.
This is same logic as gACLResource. 

.NOTES
Author: guitarrapc
Created: 3/Sep/2014

.EXAMPLE
Test-ValentiaACL -Path c:\Deployment -Account Users -Rights Modify -Ensure Present -Access Allow -Inherit $false -Recurse $false
--------------------------------------------
TestACL to the c:\Deployment for user "Users", means no Computer/Domain user name checking.

.EXAMPLE
Test-ValentiaACL -Path c:\Deployment -Account contoso\John -Rights Modify -Ensure Present -Access Allow -Inherit $false -Recurse $false
--------------------------------------------
TestACL to the c:\Deployment for user "contoso\John", means strict user name checking.

.ExternalHelp "https://github.com/guitarrapc/DSCResources/tree/master/Custom/gACLResource"
#>
function Test-ValentiaACL
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = 1, position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]$Path,

        [Parameter(Mandatory = 1, position = 1)]
        [ValidateNotNullOrEmpty()]
        [String]$Account,

        [Parameter(Mandatory = 0, position = 2)]
        [ValidateNotNullOrEmpty()]
        [System.Security.AccessControl.FileSystemRights]$Rights = "ReadAndExecute",

        [Parameter(Mandatory = 0, position = 3)]
        [ValidateSet("Present", "Absent")]
        [ValidateNotNullOrEmpty()]
        [String]$Ensure = "Present",
        
        [Parameter(Mandatory = 0, position = 4)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Allow", "Deny")]
        [System.Security.AccessControl.AccessControlType]$Access = "Allow",

        [Parameter(Mandatory = 0, position = 5)]
        [Bool]$Inherit = $false,

        [Parameter(Mandatory = 0, position = 6)]
        [Bool]$Recurse = $false,

        [Parameter(Mandatory = 0, position = 7)]
        [Bool]$Strict = $false
    )

    $desiredRule = GetDesiredRule -Path $Path -Account $Account -Rights $Rights -Access $Access -Inherit $Inherit -Recurse $Recurse
    $currentACL = (Get-Item $Path).GetAccessControl("Access")
    $currentRules = $currentACL.GetAccessRules($true, $true, [System.Security.Principal.NTAccount])
    $match = IsDesiredRuleAndCurrentRuleSame -DesiredRule $desiredRule -CurrentRules $currentRules -Strict $Strict
    
    $presence = if ($true -eq $match)
    {
        "Present"
    }
    else
    {
        "Absent"
    }
    return $presence -eq $Ensure
}