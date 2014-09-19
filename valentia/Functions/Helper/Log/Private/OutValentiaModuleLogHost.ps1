#Requires -Version 3.0

#-- Helper for valentia --#
# - Out Log and Host -#

filter OutValentiaModuleLogHost
{        
    [CmdletBinding(DefaultParameterSetName = "message")]
    param
    (
        [parameter(mandatory = 0, position  = 0, valuefromPipeline = 1, ValuefromPipelineByPropertyName = 1)]
        [string]$logmessage,

        [parameter(mandatory = 0, position  = 1)]
        [string]$logfile = $valentia.log.fullpath,

        [parameter(mandatory = 0, position  = 2)]
        [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]$encoding = $valentia.fileEncode,

        [parameter(mandatory = 0, position  = 3, ParameterSetName = "message")]
        [switch]$message,

        [parameter(mandatory = 0, position  = 3, ParameterSetName = "showdata")]
        [switch]$showdata,

        [parameter(mandatory = 0, position  = 3, ParameterSetName = "hidedata")]
        [switch]$hidedata,

        [parameter(mandatory = 0, position  = 3, ParameterSetName = "hidedataAsString")]
        [switch]$hidedataAsString,

        [parameter(mandatory = 0, position  = 3, ParameterSetName = "warning")]
        [switch]$warning,

        [parameter(mandatory = 0, position  = 3, ParameterSetName = "verbosing")]
        [switch]$verbosing,

        [parameter(mandatory = 0, position  = 3, ParameterSetName = "error")]
        [switch]$error,

        [parameter(mandatory = 0, position  = 3, ParameterSetName = "result")]
        [switch]$result,

        [parameter(mandatory = 0, position  = 3, ParameterSetName = "resultAppend")]
        [switch]$resultAppend
    )

    process
    {
        if($message)
        {
            $item = "[$(Get-Date)][message][$_]"
            Write-Host "$item" -ForegroundColor Cyan
            $item | Out-File -FilePath $logfile -Encoding $encoding -Append -Force -Width 1048
        }
        elseif($showdata)
        {
            $_
            $_ | Out-File -FilePath $logfile -Encoding $encoding -Append -Width 512
        }
        elseif($hidedata)
        {
            $_ | Out-File -FilePath $logfile -Encoding $encoding -Append -Width 512
        }
        elseif($hideDataAsString)
        {
            $item = "[$(Get-Date)][message][$_]"
            $item | Out-File -FilePath $logfile -Encoding $encoding -Append -Force -Width 1048
        }
        elseif($warning)
        {
            Write-Warning $_
            $_ | Out-File -FilePath $logfile -Encoding $encoding -Append -Width 512
        }
        elseif($verbosing)
        {
            Write-Verbose $_
            $_ | Out-File -FilePath $logfile -Encoding $encoding -Append -Width 512
        }
        elseif($error)
        {
            $_ | Out-File -FilePath $logfile -Encoding $encoding -Append -Width 512
        }
        elseif($result)
        {
            $_ | Out-File -FilePath $logfile -Encoding $encoding -Force -Width 1048
        }
        elseif($resultAppend)
        {
            $_ | Out-File -FilePath $logfile -Encoding $encoding -Force -Width 1048 -Append
        }
    }
}