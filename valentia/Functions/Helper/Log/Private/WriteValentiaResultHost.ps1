#Requires -Version 3.0

#-- Helper for valentia --#
#-- Log Output Result Settings -- #

function WriteValentiaResultHost
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory = $true)]
        [bool]$quiet,

        [parameter(mandatory = $true)]
        [System.Collections.Specialized.OrderedDictionary]$CommandResult
    )

    if (-not $quiet)
    {
        # Show Stopwatch for Total section
        Write-Verbose ("`t`tTotal duration Second`t: {0}" -f $CommandResult.TotalDuration)
        [PSCustomObject]$CommandResult
    }
    else
    {
        ([PSCustomObject]$Commandresult).Success
    }
}