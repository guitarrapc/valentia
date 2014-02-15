#Requires -Version 3.0

#-- Private Module Function for Async execution --#

function Invoke-ValentiaAsyncCommand
{

<#
.SYNOPSIS 
Creating a PowerShell pipeline then executes a ScriptBlock Asynchronous with Remote Host.

.DESCRIPTION
Pipeline will execute less overhead then Invoke-Command, Job, or PowerShell Cmdlet.
All cmdlet will execute with Invoke-Command -ComputerName -Credential wrapped by Invoke-ValentiaAsync pipeline.
Wrapped by Pipeline will give you avility to run Invoke-Command Asynchronous. (Usually Sencronous)
Asynchrnous execution will complete much faster then Syncronous execution.
   
.NOTES
Author: guitarrapc
Created: 13/July/2013

.EXAMPLE
Invoke-ValeinaAsyncCommand -RunspacePool $(New-ValentiaRunspacePool 10) `
    -ScriptBlock { Get-ChildItem } `
    -Computers $(Get-Content .\ComputerList.txt)
    -Credential $(Get-Credential)

--------------------------------------------
Above example will concurrently running with 10 processes for each Computers.

#>

    [Cmdletbinding()]
    Param
    (
        [Parameter(
            Position  = 0,
            Mandatory = 1,
            HelpMessage = "Runspace Poll required to set one or more, easy to create by New-ValentiaRunSpacePool.")]
        [System.Management.Automation.Runspaces.RunspacePool]
        $RunspacePool,
        
        [Parameter(
            Position  = 1,
            Mandatory = 1,
            HelpMessage = "The scriptblock to be executed to the Remote host.")]
        [HashTable]
        $ScriptToRunHash,
        
        [Parameter(
            Position  = 2,
            Mandatory = 1,
            HelpMessage = "Target Computers to be execute.")]
        [string[]]
        $DeployMembers,
        
        [Parameter(
            Position  = 3,
            Mandatory = 1,
            HelpMessage = "Remote Login PSCredentail for PS Remoting. (Get-Credential format)")]
        [HashTable]
        $CredentialHash,

        [Parameter(
            Position  = 4,
            Mandatory = 1,
            HelpMessage = "Input parameter pass into task's arg[0....x].")]
        [HashTable]
        $TaskParameterHash
    )


    try
    {
        # Declare execute Comdlet format as Invoke-Command
        $InvokeCommand = {
            param(
                $ScriptToRunHash,
                $ComputerName,
                $CredentialHash,
                $TaskParameterHash
            )

            $param = @{
                ScriptBlock  = $($ScriptToRunHash.Values)
                ComputerName = $($ComputerName.Values)
                Credential   = $($CredentialHash.Values)
                ArgumentList = $($TaskParameterHash.Values)
            }

            Invoke-Command @param
        }

        # Create Hashtable for ComputerName passed to Pipeline
        $ComputerName = @{ComputerName = $DeployMember}

        # Create PowerShell Instance
        Write-Verbose "Creating PowerShell Instance"
        $Pipeline = [System.Management.Automation.PowerShell]::Create()

        # Add Script and Parameter arguments from Hashtables
        Write-Verbose "Adding Script and Arguments Hastables to PowerShell Instance"
        Write-Verbose ('Add InvokeCommand Script : {0}'                          -f $InvokeCommand)
        Write-Verbose ("Add ScriptBlock Argument..... Keys : {0}, Values : {1}"  -f $($ScriptToRunHash.Keys)  , $($ScriptToRunHash.Values))
        Write-Verbose ("Add ComputerName Argument..... Keys : {0}, Values : {1}" -f $($ComputerName.Keys)     , $($ComputerName.Values))
        Write-Verbose ("Add Credential Argument..... Keys : {0}, Values : {1}"   -f $($CredentialHash.Keys)   , $($CredentialHash.Values))
        Write-Verbose ("Add ArgumentList Argument..... Keys : {0}, Values : {1}" -f $($TaskParameterHash.Keys), $($TaskParameterHash.Values))
        $Pipeline.AddScript($InvokeCommand).AddArgument($ScriptToRunHash).AddArgument($ComputerName).AddArgument($CredentialHash).AddArgument($TaskParameterHash) > $null

        # Add RunSpacePool to PowerShell Instance
        Write-Verbose ("Adding Runspaces {0}" -f $RunspacePool)
        $Pipeline.RunspacePool = $RunspacePool

        # Invoke PowerShell Command
        Write-Verbose "Invoking PowerShell Instance"
        $AsyncResult = $Pipeline.BeginInvoke() 

        # Get Result
        Write-Verbose "Obtain result"
        $Output = New-Object AsyncPipeline 
    
        # Output Pipeline Infomation
        $Output.Pipeline = $Pipeline

        # Output AsyncCommand Result
        $Output.AsyncResult = $AsyncResult
    
        Write-Verbose ("Output Result '{0}' and '{1}'" -f $Output.Pipeline, $Output.AsyncResult)
        return $Output
    }
    catch
    {
        $SuccessStatus += $false
        $ErrorMessageDetail += $_
        Write-Error $_
    }
}
