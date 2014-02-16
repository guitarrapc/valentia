#Requires -Version 3.0

#-- function helper for Dynamic Param --#

function New-ValentiaDynamicParamMulti
{
<#
.SYNOPSIS 
This cmdlet will return Dynamic param dictionary

.DESCRIPTION
You can use this cmdlet to define Dynamic Param

.NOTES
Author: guitarrapc
Created: 02/03/2014

.EXAMPLE
function Show-DynamicParamMulti
{
    [CmdletBinding()]
    param()
    
    dynamicParam
    {
        $parameters = (
            @{name         = "hoge"
              options      = "fuga"
              validateSet  = $true
              position     = 0},

            @{name         = "foo"
              options      = "bar"
              position     = 1})

        New-ValentiaDynamicParamMulti -dynamicParams $parameters
    }

    begin
    {
    }
    process
    {
        $PSBoundParameters.hoge
        $PSBoundParameters.foo
    }

}

Show-DynamicParamMulti -hoge fuga -foo bar
#>

    [CmdletBinding()]
    param
    (
        [parameter(
            mandatory = 1,
            position = 0,
            valueFromPipeline = 1,
            valueFromPipelineByPropertyName = 1)]
        [hashtable[]]
        $dynamicParams
    )

    begin
    {
        $dynamicParamLists = New-ValentiaDynamicParamList -dynamicParams $dynamicParams
        $dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
    }

    process
    {
        foreach ($dynamicParamList in $dynamicParamLists)
        {
            # create attributes
            $attributes = New-Object System.Management.Automation.ParameterAttribute
            $attributes.ParameterSetName = "__AllParameterSets"
            (
                "helpMessage",
                "mandatory",
                "parameterSetName",
                "position",
                "valueFromPipeline",
                "valueFromPipelineByPropertyName",
                "valueFromRemainingArguments"
            ) `
            | %{
                if($dynamicParamList.$_)
                {
                    $attributes.$_ = $dynamicParamList.$_
                }
            }

            # create attributes Collection
            $attributesCollection = New-Object 'Collections.ObjectModel.Collection[System.Attribute]'
            $attributesCollection.Add($attributes)
        
            # create validation set
            if ($dynamicParamList.validateSet)
            {
                $validateSetAttributes = New-Object System.Management.Automation.ValidateSetAttribute $dynamicParamList.options
                $attributesCollection.Add($validateSetAttributes)
            }

            # create RuntimeDefinedParameter
            $runtimeDefinedParameter = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter @($dynamicParamList.name, [System.String], $attributesCollection)

            # create Dictionary
            $dictionary.Add($dynamicParamList.name, $runtimeDefinedParameter)
        }
    }

    end
    {
        # return result
        return $dictionary
    }
}

function New-ValentiaDynamicParamList
{
<#
.SYNOPSIS 
This cmdlet will return Dynamic param list item for dictionary

.DESCRIPTION
You can pass this list to DynamicPramMulti to create Dynamic Param

.NOTES
Author: guitarrapc
Created: 02/03/2014

.EXAMPLE
function Show-DynamicParamMulti
{
    [CmdletBinding()]
    param()
    
    dynamicParam
    {
        $parameters = (
            @{name         = "hoge"
              options      = "fuga"
              validateSet  = $true
              position     = 0},

            @{name         = "foo"
              options      = "bar"
              position     = 1})

        $dynamicParamLists = New-ValentiaDynamicParamList -dynamicParams $parameters
        New-ValentiaDynamicParamMulti -dynamicParamLists $dynamicParamLists
    }

    begin
    {
    }
    process
    {
        $PSBoundParameters.hoge
        $PSBoundParameters.foo
    }

}

Show-DynamicParamMulti -hoge fuga -foo bar
#>
    [CmdletBinding()]
    param
    (
        [parameter(
            mandatory = 1,
            position = 0,
            valueFromPipeline = 1,
            valueFromPipelineByPropertyName = 1)]
        [hashtable[]]
        $dynamicParams
    )

    begin
    {
        # create generic list
        $list = New-Object System.Collections.Generic.List[HashTable]

        # create key check array
        [string[]]$keyCheckInputItems = "helpMessage", "mandatory", "name", "parameterSetName", "options", "position", "valueFromPipeline", "valueFromPipelineByPropertyName", "valueFromRemainingArguments", "validateSet"

        $keyCheckList = New-Object System.Collections.Generic.List[String]
        $keyCheckList.AddRange($keyCheckInputItems)

        # sort dynamicParams hashtable by position
        $newDynamicParams = Sort-ValentiaDynamicParamHashTable -dynamicParams $dynamicParams
    }

    process
    {
        foreach ($dynamicParam in $newDynamicParams)
        {
            $invalidParamter = $dynamicParam.Keys | Where {$_ -notin $keyCheckList}
            if ($($invalidParamter).count -ne 0)
            {
                throw ("Invalid parameter '{0}' found. Please use parameter from '{1}'" -f $invalidParamter, ("$keyCheckInputItems" -replace " "," ,"))
            }
            else
            {
                if (-not $dynamicParam.Keys.contains("name"))
                {
                    throw ("You must specify mandatory parameter '{0}' to hashtable key." -f "name")
                }
                elseif (-not $dynamicParam.Keys.contains("options"))
                {
                    throw ("You must specify mandatory parameter '{0}' to hashtable key." -f "options")
                }
                else
                {
                    $list.Add($dynamicParam)
                }
            }
        }
    }

    end
    {
        return $list
    }
}


function Sort-ValentiaDynamicParamHashTable
{
    [CmdletBinding()]
    param
    (
        [parameter(
            mandatory = 1,
            position = 0,
            valueFromPipeline = 1,
            valueFromPipelineByPropertyName = 1)]
        [hashtable[]]
        $dynamicParams
    )

    begin
    {
        # get max number of position for null position item
        $max = ($dynamicParams.position | measure -Maximum).Maximum
    }

    process
    {
        # output PSCustomObject[Name<SortedPosition>,Value<DynamicParamHashTable>]. posision is now sorted.
        $h = $dynamicParams `
        | %{
            $history = New-Object System.Collections.Generic.List[int]
            $hash = @{}
            
            # temp posision for null item. This set as (max + number of collection items)
            $num = $max + $parameters.Length
        }{
            ("position is '{0}'." -f $position) | Write-ValentiaVerboseDebug
            $position = $_.position
            
            #region null check
            if ($null -eq $position)
            {
                ("position is '{0}'. set current max index '{1}'" -f $position, $num) | Write-ValentiaVerboseDebug
                $position = $num
                $num++
            }
            #endregion

            #region dupricate check
            if ($position -notin $history)
            {
                ("position '{0}' not found in '{1}'. Add to history." -f $position, ($history -join ", ")) | Write-ValentiaVerboseDebug
                $history.Add($position)
            }
            else
            {
                $changed = $false
                while ($position -in $history)
                {
                    ("position '{0}' found in '{1}'. Start increment." -f $position, ($history -join ", ")) | Write-ValentiaVerboseDebug
                    $position++
                    $changed = $true
                }
                (" incremented position '{0}' not found in '{1}'. Add to history." -f $position, ($history -join ", ")) | Write-ValentiaVerboseDebug
                if ($changed){$history.Add($position)}
            }
            #endregion

            #region set temp hash
            ("Set position '{0}' as name of temp hash." -f $position) | Write-ValentiaVerboseDebug
            $hash."$position" = $_
            #endregion
        }{[PSCustomObject]$hash}
    }

    end
    {
        # get index for each object
        $index = [int[]](($h | Get-Member -MemberType NoteProperty).Name) | sort
        
        # return sorted hash order by index
        return $index | %{$h.$_}
    }
}