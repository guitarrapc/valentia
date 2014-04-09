#Requires -Version 3.0

#-- Helper Functions --#

<#
.SYNOPSIS 
Get encoding from the file your tried to read.

.DESCRIPTION
You can specify what is the encoding used in the file you want to check.
Will return encoding name used in PowerShell, it means you can pass returned value to Get-Content or other.

.NOTES
Author: guitarrapc
Created: 19/Nov/2013

.EXAMPLE
Get-ValentiaFileEncoding -Path hogehoge.ps1
--------------------------------------------
Get encoding of hogehoge.ps1
#>
function Get-ValentiaFileEncoding
{
    [CmdletBinding()]
    param
    (
        [parameter(
            mandatory = 1,
            position = 0)]
        [string]
        $path
    )

    if (Test-Path $path)
    {
        $bytes = [byte[]](Get-Content $Path -Encoding byte -ReadCount 4 -TotalCount 4)

        if(-not $bytes)
        {
            return 'utf8'
        }

        switch -regex ('{0:x2}{1:x2}{2:x2}{3:x2}' -f $bytes[0],$bytes[1],$bytes[2],$bytes[3])
        {
            '^efbbbf'   {return 'utf8'}
            '^2b2f76'   {return 'utf7'}
            '^fffe'     {return 'unicode'}
            '^feff'     {return 'bigendianunicode'}
            '^0000feff' {return 'utf32'}
            default     {return 'ascii'}
        }
    }
    else
    {
        throw ("path '{0}' not exist excemption." -f $path)
    }
}