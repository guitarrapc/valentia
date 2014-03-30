#Requires -Version 3.0

#-- helper for write verbose and debug --#

<#
.SYNOPSIS 
Pass to write-verbose / debug for input.

.DESCRIPTION
You can show same message for verbose and debug.

.NOTES
Author: guitarrapc
Created: 16/Feb/2014

.EXAMPLE
"hoge" | Write-ValentiaVerboseDebug
--------------------------------------------
Will show both Verbose message and Debug.
#>
filter Write-ValentiaVerboseDebug
{
    Write-Verbose -Message $_
    Write-Debug -Message $_
}