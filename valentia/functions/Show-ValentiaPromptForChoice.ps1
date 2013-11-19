#Requires -Version 3.0

# -- helper function -- #

function Show-ValentiaPromptForChoice
{
<#

.SYNOPSIS 
Show valentia Prompt For Choice description and will return item you passed.

.DESCRIPTION
You can show choice Description with your favored items.

.NOTES
Author: guitarrapc
Created: 17/Nov/2013

.EXAMPLE
Show-ValentiaPromptForChoice
--------------------------------------------
default will use what you have written in valentia-config.ps1

.EXAMPLE
Show-ValentiaPromptForChoice -questionHelps $(Show-ValentiaGroup).Name 
--------------------------------------------
Will check valentia deploy folder and get deploygroup files.
You can see choice description for each deploygroup file, and will get which item was selected.

#>

    [CmdletBinding()]
    param
    (
        # input prompt items with array. second index is for help message.
        [parameter(
            mandatory = 0,
            position = 0)]
        [string[]]
        $questions = $valentia.promptForChoice.questions,

        # input title message showing when prompt.
        [parameter(
            mandatory = 0,
            position = 1)]
        [string[]]
        $title = $valentia.promptForChoice.title,
                
        # input message showing when prompt.
        [parameter(
            mandatory = 0,
            position = 2)]
        [string]
        $message = $valentia.promptForChoice.message,

        # input additional message showing under message.
        [parameter(
            mandatory = 0,
            position = 3)]
        [string]
        $additionalMessage = $valentia.promptForChoice.additionalMessage,
        
        # input Index default selected when prompt.
        [parameter(
            mandatory = 0,
            position = 4)]
        [int]
        $defaultIndex = $valentia.promptForChoice.defaultIndex
    )

    $ErrorActionPreference = $valentia.errorPreference
    
    try
    {
        # create caption Messages
        if(-not [string]::IsNullOrEmpty($additionalMessage))
        {
            $message += ([System.Environment]::NewLine + $additionalMessage)
        }

        # create dictionary include dictionary <int, KV<string, string>> : accessing KV <string, string> with int key return from prompt
        $script:dictionary = New-Object 'System.Collections.Generic.Dictionary[int, System.Collections.Generic.KeyValuePair[string, string]]'
		
        foreach ($question in $questions)
        {
            # create key to access value
            $private:key = [System.Text.Encoding]::ASCII.GetString($([byte[]][char[]]'a') + [int]$private:count)

            # create KeyValuePair<string, string> for prompt item : accessing value with 1 letter Alphabet by converting char
            $script:keyValuePair = New-Object 'System.Collections.Generic.KeyValuePair[string, string]'($key, $question)
            
            # add to Dictionary
            $dictionary.Add($count, $keyValuePair)

			# increment to next char
            $count++

            # prompt limit to max 26 items as using single Alphabet charactors.
            if ($count -gt 26)
            {
                throw ("Not allowed to pass more then '{0}' items for prompt" -f ($dictionary.Keys).count)
            }
        }

        # create choices Collection
        $script:collectionType = [System.Management.Automation.Host.ChoiceDescription]
        $script:choices = New-Object "System.Collections.ObjectModel.Collection[$CollectionType]"

        # create choice description from dictionary<int, KV<string, string>>
        foreach ($dict in $dictionary.GetEnumerator())
        {
            foreach ($kv in $dict)
            {
                # create prompt choice item. Currently you could not use help message.
                $private:choice = (("&{0}:{1}" -f $kv.Value.Key, $kv.Value.Value), ($valentia.promptForChoice.helpMessage -f $MyInvocation.MyCommand))
                $choices.Add((New-Object $CollectionType $choice))
            }
        }

        # show choices on host
        $script:answer = $host.UI.PromptForChoice($title, $message, $choices, $defaultIndex)

        # return value from key
        return ($dictionary.GetEnumerator() | where Key -eq $answer).Value.Value
    }
    catch
    {
        throw $_
    }
}