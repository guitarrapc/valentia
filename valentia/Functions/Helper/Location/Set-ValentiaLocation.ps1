#Requires -Version 3.0

#-- Helper for valentia --#

# go
<#
.SYNOPSIS 
Move location to valentia folder

.DESCRIPTION
You can specify branch path in configuration.
If you changed from default, then change validation set for BranchPath for intellisence.

.NOTES
Author: guitarrapc
Created: 13/Jul/2013

.EXAMPLE
go
--------------------------------------------
just move to root deployment path.

.EXAMPLE
go application
--------------------------------------------
change location to BranchPath c:\deployment\application (in default configuration.)
#>
function Set-ValentiaLocation
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, mandatory = $false, HelpMessage = "Select branch deploy folder to change directory.")]
        [ValentiaBranchPath]$BranchPath
    )

    begin
    {
        $prevLocation = (Get-Location).Path
        $newlocation = Join-Path $valentia.RootPath ([ValentiaBranchPath]::$BranchPath)
    }

    process
    {
        # Move to BrachPath if exist
        ("moving to new location as '{0}' : '{1}'" -f $BranchPath, $newlocation) | Write-ValentiaVerboseDebug
        if (Test-Path $newlocation)
        {
            Set-Location -Path $newlocation
        }
        else
        {
            throw "Path not found exception! Make sure {0} is exist." -f $newlocation
        }
    }

    end
    {
        ("moved Location : '{0}', previous Location : '{1}'" -f (Get-Location).Path, $prevLocation) | Write-ValentiaVerboseDebug
        if ((Get-Location).Path -ne $prevLocation)
        {
            ("Location change to '{0}'" -f (Get-Location).Path) | Write-ValentiaVerboseDebug
        }
        else
        {
            Write-Warning "Location not changed."
        }
    }
}
