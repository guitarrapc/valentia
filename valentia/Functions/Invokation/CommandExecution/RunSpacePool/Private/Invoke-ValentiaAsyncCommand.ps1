#Requires -Version 3.0

#-- Private Module Function for Async execution --#

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
function Invoke-ValentiaAsyncCommand
{
    [Cmdletbinding()]
    Param
    (
        [Parameter(Position  = 0, mandatory = $true, HelpMessage = "Runspace Poll required to set one or more, easy to create by New-ValentiaRunSpacePool.")]
        [System.Management.Automation.Runspaces.RunspacePool]$RunspacePool,
        
        [Parameter(Position  = 1, mandatory = $true, HelpMessage = "The scriptblock to be executed to the Remote host.")]
        [HashTable]$ScriptToRunHash,
        
        [Parameter(Position  = 2, mandatory = $true, HelpMessage = "Target Computers to be execute.")]
        [string[]]$DeployMembers,
        
        [Parameter(Position  = 3, mandatory = $true, HelpMessage = "Remote Login PSCredentail for PS Remoting. (Get-Credential format)")]
        [HashTable]$CredentialHash,

        [Parameter(Position  = 4, mandatory = $true, HelpMessage = "Input parameter pass into task's arg[0....x].")]
        [HashTable]$TaskParameterHash,

        [Parameter(Position  = 5, mandatory = $true, HelpMessage = "Input Authentication for credential.")]
        [HashTable]$AuthenticationHash,

        [Parameter(Position  = 6, mandatory = $true, HelpMessage = "Select SSL is use or not.")]
        [HashTable]$UseSSLHash
    )

    end
    {
        try
        {
            # Create PowerShell Instance
            "Creating PowerShell Instance" | Write-ValentiaVerboseDebug
            $Pipeline = [System.Management.Automation.PowerShell]::Create()

            # Add Script and Parameter arguments from Hashtables
            "Adding Script and Arguments Hastables to PowerShell Instance" | Write-ValentiaVerboseDebug
            Write-Verbose ('Add InvokeCommand Script : {0}'                          -f   $InvokeCommand)
            Write-Verbose ("Add ScriptBlock Argument..... Keys : {0}, Values : {1}"  -f   $($ScriptToRunHash.Keys)   , $($ScriptToRunHash.Values))
            Write-Verbose ("Add ComputerName Argument..... Keys : {0}, Values : {1}" -f   $($ComputerName.Keys)      , $($ComputerName.Values))
            Write-Verbose ("Add Credential Argument..... Keys : {0}, Values : {1}"   -f   $($CredentialHash.Keys)    , $($CredentialHash.Values))
            Write-Verbose ("Add ArgumentList Argument..... Keys : {0}, Values : {1}" -f   $($TaskParameterHash.Keys) , $($TaskParameterHash.Values))
            Write-Verbose ("Add Authentication Argument..... Keys : {0}, Values : {1}" -f $($AuthenticationHash.Keys), $($AuthenticationHash.Values))
            Write-Verbose ("Add UseSSL Argument..... Keys : {0}, Values : {1}"       -f $($UseSSLHash.Keys), $($UseSSLHash.Values))
            $Pipeline.
                AddScript($InvokeCommand).
                AddArgument($ScriptToRunHash).
                AddArgument($ComputerName).
                AddArgument($CredentialHash).
                AddArgument($TaskParameterHash).
                AddArgument($AuthenticationHash).
                AddArgument($UseSSLHash) > $null

            # Add RunSpacePool to PowerShell Instance
            ("Adding Runspaces {0}" -f $RunspacePool) | Write-ValentiaVerboseDebug
            $Pipeline.RunspacePool = $RunspacePool

            # Invoke PowerShell Command
            "Invoking PowerShell Instance" | Write-ValentiaVerboseDebug
            $AsyncResult = $Pipeline.BeginInvoke() 

            # Get Result
            Write-Verbose "Obtain result"
            $Output = New-Object AsyncPipeline 
    
            # Output Pipeline Infomation
            $Output.Pipeline = $Pipeline

            # Output AsyncCommand Result
            $Output.AsyncResult = $AsyncResult
    
            ("Output Result '{0}' and '{1}'" -f $Output.Pipeline, $Output.AsyncResult) | Write-ValentiaVerboseDebug
            return $Output
        }
        catch
        {
            $valentia.Result.SuccessStatus += $false
            $valentia.Result.ErrorMessageDetail += $_
            Write-Error $_
        }
    }

    begin
    {
        # Create Hashtable for ComputerName passed to Pipeline
        $ComputerName = @{ComputerName = $DeployMember}

        # Declare execute Comdlet format as Invoke-Command
        $InvokeCommand = {
            param(
                $ScriptToRunHash,
                $ComputerName,
                $CredentialHash,
                $TaskParameterHash,
                $AuthenticationHash,
                $UseSSLHash
            )

            $param = @{
                ScriptBlock    = $($ScriptToRunHash.Values)
                ComputerName   = $($ComputerName.Values)
                Credential     = $($CredentialHash.Values)
                ArgumentList   = $($TaskParameterHash.Values)
                Authentication = $($AuthenticationHash.Values)
                UseSSL         = $($UseSSLHash.Values)
            }

            Invoke-Command @param
        }
    }
}
