#Requires -Version 3.0

#-- helper for DNS Entry --#

<#
.Synopsis
   Get HostName to IPAddress Entry / IPAddress to HostName Entry

.DESCRIPTION
   using Dns.GetHostEntryAsync Method. 
   You can skip Exception for none exist HostNameOrAddress result by adding -SkipException $true

.EXAMPLE
Get-HostEntryAsync -HostNameOrAddress "google.com", "173.194.38.100", "neue.cc"
# Test Success

.EXAMPLE
"google.com", "173.194.38.100", "neue.cc" | Get-HostEntryAsync
# Pipeline Input

.EXAMPLE
Get-HostEntryAsync -HostNameOrAddress "google.com", "173.194.38.100", "hogemopge.fugapiyo"
# Error will stop execution

.EXAMPLE
Get-HostEntryAsync -HostNameOrAddress "google.com", "173.194.38.100", "hogemopge.fugapiyo" -SkipException $true
# Skip Error result

.LINK
    http://msdn.microsoft.com/en-US/library/system.net.dns.gethostentryasync(v=vs.110).aspx
#>
function Get-ValentiaHostEntryAsync
{
    [CmdletBinding()]
    param
    (
        [parameter(
            Mandatory = 1,
            Position  = 0,
            ValueFromPipeline = 1,
            ValueFromPipelineByPropertyName = 1)]
        [string[]]
        $HostNameOrAddress,

        [parameter(
            Mandatory = 0,
            Position  = 1,
            ValueFromPipelineByPropertyName = 1)]
        [bool]
        $SkipException = $false
    )

    process
    {
        foreach ($name in $HostNameOrAddress)
        {
            $x = [System.Net.DNS]::GetHostEntryAsync($name)
            $x.ConfigureAwait($false) > $null
            $task = [PSCustomObject]@{
                HostNameOrAddress = $name
                Task              = $x
            }
            $tasks.Add($task)
        }
    }

    end
    {
        try
        {
            [System.Threading.Tasks.Task]::WaitAll($tasks.Task)
        }
        catch
        {
            $stackStrace = $_ 
            $throw = $Tasks `
            | where {$_.Task.Exception} `
            | %{
                $stackStrace
                [System.Environment]::NewLine
                "Error HostNameOrAddress : {0}" -f $_.HostNameOrAddress                    
                [System.Environment]::NewLine
                $_.Task.Exception
            }

            if (-not $SkipException)
            {
                throw $throw
            }
            else
            {
                Write-Verbose ("-SkipException was {0}. Skipping Error : '{1}'." -f $SkipException, "$(($Tasks | where {$_.Task.Exception}).HostNameOrAddress -join ', ')")
            }
        }
        finally
        {
            foreach ($task in $tasks.Task)
            {
                [System.Net.IPHostEntry]$IPHostEntry = $task.Result
                $IPHostEntry
            }
        }
    }
    
    begin
    {
        $tasks = New-Object 'System.Collections.Generic.List[PSCustomObject]'
    }
}