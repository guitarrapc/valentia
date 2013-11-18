#Requires -Version 3.0

#-- Helper for valentia --#

# go
function Set-ValentiaLocation
{

<#
.SYNOPSIS 
Move location to valentia folder

.DESCRIPTION
You can specify branch path in configuration.
If you changed from default, then change validation set for BranchPath for intellisence.

.NOTES
Author: Ikiru Yoshizaki
Created: 13/Jul/2013

.EXAMPLE
go -BrachPath BranchPathName
--------------------------------------------
Move location to valentia root path

.EXAMPLE
go
--------------------------------------------
just move to root path

.EXAMPLE
go application
--------------------------------------------
change location to BranchPath c:\deployment\application (in default)

#>

    [CmdletBinding()]
    param
    (
        [Parameter(
            Position = 0,
            Mandatory = 0,
            HelpMessage = "Select branch deploy folder to change directory.")]
        [validateSet(
            "Application",
            "Bin",
            "DeployGroup",
            "Download",
            "Maintenance",
            "Upload",
            "Utils")]
        [string]
        $BranchPath
    )

    $prevLocation = (Get-Location).Path

    # replace \ to \\ for regexpression
    $valentiaroot = $valentia.RootPath -replace "\\","\\"

    # Create target path
    $newlocation = (Join-Path $valentia.RootPath $valentia.BranchFolder.$BranchPath)

    # Move to BrachPath if exist
    Write-Verbose ("{0} : {1}" -f $BranchPath, $newlocation)
    if (Test-Path $newlocation)
    {
        switch ($BranchPath) {
            $valentia.BranchFolder.$BranchPath {Set-Location $newlocation}
            default {}
        }
    }
    else
    {
        throw "{0} not found exception! Make sure {1} is exist." -f $newlocation, $newlocation
    }

    # Show current Loacation
    Write-Verbose ("(Get-Location).Path : {0}" -f (Get-Location).Path)
    Write-Verbose ("prevLocation : {0}" -f $prevLocation)
    if ((Get-Location).Path -eq $prevLocation)
    {
        Write-Warning "Location not changed."
    }
    else
    {
        Write-Verbose ("Location change to {0}" -f (Get-Location).Path)
    }
}
