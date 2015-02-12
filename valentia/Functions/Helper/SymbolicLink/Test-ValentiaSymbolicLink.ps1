#Requires -Version 3.0

#-- SymbolicLink Functions --#

<#
.SYNOPSIS 
This function will Test whether target path is Symbolic Link or not.

.DESCRIPTION
If target is Symbolic Link (reparse point), function will return $true.
Others, return $false.

.NOTES
Author: guitarrapc
Created: 12/Feb/2015

.EXAMPLE
Test-ValentiaSymbolicLink -Path "d:\SymbolicLink"
--------------------------------------------
As Path is Symbolic Link, this returns $true.

#>
function Test-ValentiaSymbolicLink
{
    [OutputType([System.IO.DirectoryInfo[]])]
    [cmdletBinding()]
    param
    (
        [parameter(Mandatory = 1, Position  = 0, ValueFromPipeline =1, ValueFromPipelineByPropertyName = 1)]
        [Alias('FullName')]
        [String]$Path
    )
    
    process
    {
        $result = Get-ValentiaSymbolicLink -Path $Path
        if ($null -eq $result){ return $false }
        return $true
    }

    begin
    {
        $script:ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
    }
}
