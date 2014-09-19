#Requires -Version 3.0

#-- Helper for valentia --#
#-- Log Output Result Settings -- #

function OutValentiaResultLog
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = 1)]
        [System.Collections.Specialized.OrderedDictionary]
        $CommandResult,

        [parameter(Mandatory = 0)]
        [string]
        $removeProperty = "Result",

        [bool]
        $Append = $false
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