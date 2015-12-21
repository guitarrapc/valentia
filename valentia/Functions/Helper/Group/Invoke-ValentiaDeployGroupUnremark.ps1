#Requires -Version 3.0

#-- Deploy Folder/File Module Functions --#

# ipunremark

<#
.SYNOPSIS 
Unremark Deploy ip from deploygroup file

.DESCRIPTION
This cmdlet unremark deploygroup ipaddresses from $valentia.root\$valentia.branch.deploygroup to refer the ipaddress.

.NOTES
Author: guitarrapc
Created: 04/Oct/2013

.EXAMPLE
Invoke-valentiaDeployGroupUnremark -unremarkIPAddresses 10.0.0.10,10.0.0.11 -overWrite -Verbose
--------------------------------------------
replace #10.0.0.10 and #10.0.0.11 with 10.0.0.10 and 10.0.0.11 then replace file (like sed -f "s/^#10.0.0.10$/10.0.0.10" -i)

Invoke-valentiaDeployGroupUnremark -unremarkIPAddresses 10.0.0.10,10.0.0.11 -Verbose
--------------------------------------------
replace #10.0.0.10 and #10.0.0.11 with 10.0.0.10 and 10.0.0.11 (like sed -f "s/^#10.0.0.10$/10.0.0.10")

Invoke-valentiaDeployGroupUnremark -remarkIPAddresses 10.0.0.10,10.0.0.11 -Verbose -Recurse $false -Path d:\hoge
--------------------------------------------
Check d:\hoge folder without recursive. This means it only check path you desired.
#>
function Invoke-ValentiaDeployGroupUnremark
{
    [CmdletBinding()]
    param
    (
        [parameter(position = 0, mandatory = $true, ValueFromPipeline = 1, ValueFromPipelineByPropertyName = 1)]
        [Alias("IPAddress", "HostName")]
        [string[]]$unremarkIPAddresses,

        [parameter(position = 1, mandatory = $false, ValueFromPipelineByPropertyName = 1)]
        [string]$Path = (Join-Path $valentia.RootPath ([ValentiaBranchPath]::Deploygroup)),

        [parameter(position = 2, mandatory = $false, ValueFromPipelineByPropertyName = 1)]
        [bool]$Recurse = $true,

        [parameter(position = 3, mandatory = $false)]
        [switch]$overWrite,

        [parameter(position = 4, mandatory = $false)]
        [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]
        $encoding = $valentia.fileEncode
    )

    begin
    {
        if (-not (Test-Path $Path)){ throw New-Object System.IO.FileNotFoundException ("Path $Path not found Exception!!", "$Path")}
    }

    end
    {
        Get-ChildItem -Path $Path -Recurse:$Recurse -File `
        | %{
            foreach ($unremarkIPAddress in $unremarkIPAddresses)
            {
                if ($overWrite)
                {
                    Invoke-ValentiaSed -path $_.FullName -searchPattern "^#$unremarkIPAddress$" -replaceWith "$unremarkIPAddress" -encoding $encoding -overWrite
                }
                else
                {
                    Invoke-ValentiaSed -path $_.FullName -searchPattern "^#$unremarkIPAddress$" -replaceWith "$unremarkIPAddress" -encoding $encoding
                }
            }
        }
    }
}
