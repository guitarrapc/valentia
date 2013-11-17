function Show-ValentiaPromptForChoice
{
    [CmdletBinding()]
    param
    (
        [parameter(
            mandatory = 0,
            position = 0)]
        [string[]]
        $title = $valentia.promptForChoice.title,

        [parameter(
            mandatory = 0,
            position = 1)]
        [string[]]
        $questionHelps = $valentia.promptForChoice.questionHelps,
                
        [parameter(
            mandatory = 0,
            position = 2)]
        [string]
        $message = $valentia.promptForChoice.message,

        [parameter(
            mandatory = 0,
            position = 3)]
        [string]
        $additionalMessage = $valentia.promptForChoice.additionalMessage,
        
        [parameter(
            mandatory = 0,
            position = 4)]
        [int]
        $defaultIndex = $valentia.promptForChoice.defaultIndex
    )

    $ErrorActionPreference = $valentia.errorPreference
    
    try
    {
        # create choice description
        $script:collectionType = [System.Management.Automation.Host.ChoiceDescription]
        $script:descriptions = New-Object "System.Collections.ObjectModel.Collection``1[$CollectionType]"

        # create dictionary for prompt item
        $script:dictionary = New-Object 'System.Collections.Generic.Dictionary``2[int,string]'
        $script:count = 0
        foreach ($questionHelp in $questionHelps)
        {
            $dictionary.Add($count, $questionHelp)
            $count++
        }

        # create choice description from dictionary
        foreach ($dict in $dictionary.GetEnumerator())
        {
            $q = "&{0} : {1}" -f $dict.Key, $dict.Value
            $descriptions.Add((New-Object $CollectionType $q))
        }

        # create caption Messages
        if(-not [string]::IsNullOrEmpty($additionalMessage))
        {
            $message += ([System.Environment]::NewLine + $additionalMessage)
        }

        # show prompt message and copnfirm
        $script:answer = $host.UI.PromptForChoice($title, $message, $descriptions, $defaultIndex)

        # return value from key
        return ($dictionary.GetEnumerator() | where Key -eq $answer).Value
    }
    catch
    {
        throw $_
    }
}