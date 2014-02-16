#Requires -Version 3.0

#-- Helper Function --#

function ConvertTo-ValentiaTask
{
<#

.SYNOPSIS 
Convert PowerShell script to Valentia Task format

.DESCRIPTION
You can specify "filepath for PowerShell Script" or "scriptBlock".
This Cmldet will automatically add "task $taskname -Action {" on top and "}" on bottom.

.NOTES
Author: guitarrapc
Created: 18/Nov/2013

.EXAMPLE
ConvertTo-ValentiaTask -inputFilePath d:\hogehoge.ps1 -taskName hoge -outputFilePath d:\fuga.ps1
--------------------------------------------
Convert PowerShell Script written in inputFilePath into valentia Task file.

.EXAMPLE
ConvertTo-ValentiaTask -scriptBlock {ps} -taskName test -outputFilePath d:\test.ps1
--------------------------------------------
Convert ScriptBlock into valentia Task file.

#>

    [CmdletBinding(DefaultParameterSetName = "File")]
    param
    (
        # Path to PowerShell Script .ps1 you want to convert into Task
        [Parameter(
            Position = 0,
            Mandatory = 1,
            ParameterSetName = "File")]
        [string]
        $inputFilePath,
    
        # Path to PowerShell Script .ps1 you want to convert into Task
        [Parameter(
            Position = 1,
            Mandatory = 0,
            ParameterSetName = "File")]
        [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]
        $encoding = $valentia.fileEncode,

        # Script Block to Convert into Task
        [Parameter(
            Position = 0,
            Mandatory = 1,
            ParameterSetName = "Script")]
        [scriptBlock]
        $scriptBlock,

        # Task Name you want to set
        [Parameter(
            Position = 1,
            Mandatory = 1)]
        [string]
        $taskName,

        # Path to output Task
        [Parameter(
            Position = 2,
            Mandatory = 1)]
        [string]
        $outputFilePath
    )

    begin
    {
        $ErrorActionPreference = $valentia.errorPreference

        if ($PSBoundParameters.inputFilePath)
        {
            if (Test-Path $inputFilePath)
            {
                $read = Get-Content -Path $inputFilePath -Encoding $encoding -Raw
            }
            else
            {
                throw ("Path not found exception. file path '{0}' not exists." -f $inputFilePath)
            }
        }
        elseif ($PSBoundParameters.scriptBlock)
        {
            $read = $scriptBlock
        }
    }

    process
    {
        try
        {
            # create String Builder
            $sb = New-Object System.Text.StringBuilder

            # append Header
            $sb.AppendLine($("Task {0} -Action {1}" -f $taskName,"{")) > $null

            # append Original source
            $sb.AppendLine($read) > $null

            # append end charactor
            $sb.AppendLine("}") > $null

            # serialize
            $output = $sb.ToString()
        }
        finally
        {
            $sb.Clear() > $null
        }
        
    }

    end
    {
        $output | Out-File -FilePath $outputFilePath -Encoding $valentia.fileEncode
    }
    
}