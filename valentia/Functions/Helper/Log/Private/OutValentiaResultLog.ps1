#Requires -Version 3.0

#-- Helper for valentia --#
#-- Log Output Result Settings -- #

function OutValentiaResultLog
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory = $true)]
        [System.Collections.Specialized.OrderedDictionary]$CommandResult,

        [parameter(mandatory = $false)]
        [string]$removeProperty = "Result",

        [bool]$Append = $false
    )

    try
    {
        $json = $CommandResult | ConvertTo-Json
    }
    catch
    {
        $json = $CommandResult.Remove($removeProperty) | ConvertTo-Json
    }
    finally
    {
        if ($Append)
        {
            $json | OutValentiaModuleLogHost -resultAppend
        }
        else
        {
            $json | OutValentiaModuleLogHost -result
        }
    }
}