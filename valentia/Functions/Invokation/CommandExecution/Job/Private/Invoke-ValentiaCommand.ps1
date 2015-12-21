#Requires -Version 3.0

#-- Private Module Job / Functions for Remote Execution --#

<#
.SYNOPSIS 
Invoke Command as Job to remote host

.DESCRIPTION
Background job execution with Invoke-Command.
Allowed to run from C# code.

.NOTES
Author: guitarrapc
Created: 20/June/2013

.EXAMPLE
  Invoke-ValentiaCommand -ScriptToRun $ScriptToRun

.EXAMPLE
  Invoke-ValentiaCommand -ScriptToRun {ls}

.EXAMPLE
  Invoke-ValentiaCommand -ScriptToRun {ls | where {$_.extensions -eq ".txt"}}

.EXAMPLE
  Invoke-ValentiaCommand {test-connection localhost}
#>
function Invoke-ValentiaCommand
{
    [CmdletBinding(DefaultParameterSetName = "All")]
    param
    (
        [Parameter(Position = 0, mandatory = $true, ParameterSetName = "Default", ValueFromPipeline = 1, ValueFromPipelineByPropertyName = 1, HelpMessage = "Input Session")]
        [string[]]$ComputerNames,

        [Parameter(Position = 1, mandatory = $true, ParameterSetName = "Default", ValueFromPipeline = 1, ValueFromPipelineByPropertyName = 1, HelpMessage = "Input ScriptBlock. ex) Get-ChildItem, Get-NetAdaptor | where MTUSize -gt 1400")]
        [ScriptBlock]$ScriptToRun,

        [Parameter(Position = 2, mandatory = $true, HelpMessage = "Input PSCredential for Remote Command execution.")]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(Position = 3, mandatory = $false, HelpMessage = "Input parameter pass into task's arg[0....x].")]
        [hashtable]$TaskParameter,

        [Parameter(Position = 4, mandatory = $false, HelpMessage = "Input Authentication for credential.")]
        [System.Management.Automation.Runspaces.AuthenticationMechanism]$Authentication,

        [Parameter(Position = 5, mandatory = $false, HelpMessage = "Input SSL is use or not.")]
        [bool]$UseSSL,

        [Parameter(Position = 6, mandatory = $false, HelpMessage = "Input Skip ErrorActionPreferenceOption.")]
        [bool]$SkipException
    )

    process
    {
        foreach ($computerName in $ComputerNames)
        {
            # Run ScriptBlock in Job
            Write-Verbose ("ScriptBlock..... {0}" -f $($ScriptToRun))
            Write-Verbose ("Argumentlist..... {0}" -f $($TaskParameter))
            ("Running ScriptBlock to {0} as Job" -f $computerName) | Write-ValentiaVerboseDebug
            $job = Invoke-Command -ScriptBlock $ScriptToRun -ArgumentList $TaskParameter -ComputerName $computerName -Credential $Credential -Authentication $Authentication -UseSSL:$UseSSL -AsJob
            $list.Add($job)
        }

        # receive job result
        "Receive all job result." | Write-ValentiaVerboseDebug
        $jobParam = @{
            listJob       = $list
            SkipException = $skipException
            ErrorAction   = $ErrorActionPreference
        }
        Receive-ValentiaResult @jobParam
    }

    begin
    {
        $list = New-Object System.Collections.Generic.List[System.Management.Automation.Job]

        # Set variable for output each task result
        $task = @{}

        # Cleanup previous Job before start
        if ((Get-Job).count -gt 0)
        {
            "Clean up previous Job" | Write-ValentiaVerboseDebug
            Get-Job | Remove-Job -Force -Verbose:$VerbosePreference
        }
    }
}