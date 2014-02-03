#Requires -Version 3.0

#-- function helper for Dynamic Param --#

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

    }
    process
    {
        foreach ($dynamicParam in $dynamicParams)
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

    param
    (
        [parameter(
            mandatory = 1,
            position = 0)]
        [System.Collections.Generic.List[HashTable]]
        $dynamicParamLists
    )

    $dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

    foreach ($dynamicParamList in $dynamicParamLists)
    {
        # create attributes
        $attributes = New-Object System.Management.Automation.ParameterAttribute
        $attributes.ParameterSetName = "__AllParameterSets"
        if($dynamicParamList.helpMessage){$attributes.helpMessage = $dynamicParamList.helpMessage}                                                            # helpMessage
        if($dynamicParamList.mandatory){$attributes.mandatory = $dynamicParamList.mandatory}                                                                  # mandatory
        if($dynamicParamList.parameterSetName -ne $null){$attributes.parameterSetName = $dynamicParamList.parameterSetName}                                   # parameterSetName
        if($dynamicParamList.position -ne $null){$attributes.position = $dynamicParamList.position}                                                           # position
        if($dynamicParamList.valueFromPipeline -ne $null){$attributes.valueFromPiprline = $dynamicParamList.valueFromPiprline}                                # valueFromPiprline
        if($dynamicParamList.valueFromPipelineByPropertyName){$attributes.valueFromPipelineByPropertyName = $dynamicParamList.valueFromPipelineByProperyName} # valueFromPipelineByPropertyName
        if($dynamicParamList.valueFromRemainingArguments){$attributes.valueFromRemainingArguments = $dynamicParamList.ValueFromRemainingArguments}            # valueFromRemainingArguments

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

    # return result
    return $dictionary

}