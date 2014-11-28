#Requires -Version 3.0

function IsDesiredRuleAndCurrentRuleSame
{
    [OutputType([Bool])]
    [CmdletBinding()]
    param
    (
        [System.Security.AccessControl.FileSystemAccessRule]$DesiredRule,
        [System.Security.AccessControl.AuthorizationRuleCollection]$CurrentRules,
        [bool]$Strict
    )

    $match = if ($Strict)
    {
        $currentRules `
        | where {$_.IdentityReference.Value -eq $DesiredRule.IdentityReference.Value} `
        | where FileSystemRights -eq $DesiredRule.FileSystemRights `
        | where AccessControlType -eq $DesiredRule.AccessControlType `
        | where Inherit -eq $_.InheritanceFlags `
        | measure
    }
    else
    {
        $currentRules `
        | where {$_.IdentityReference.Value.Split("\")[1] -eq $DesiredRule.IdentityReference.Value} `
        | where FileSystemRights -eq $DesiredRule.FileSystemRights `
        | where AccessControlType -eq $DesiredRule.AccessControlType `
        | where Inherit -eq $_.InheritanceFlags `
        | measure
    }

    return $match.Count -ge 1
}
