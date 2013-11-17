#Requires -Version 3.0

#-- Public Loading Module Functions --#

# reload
function Get-ValentiaModuleReload
{

    [CmdletBinding()]
    param
    (
        [Parameter(
            Position = 0,
            Mandatory = 0)]
        [ValidateScript({Get-Module -Name $ModuleName})]
        $ModuleName = "valentia",

        [Parameter(
            Position = 1,
            Mandatory = 0)]
        [string]
        $scriptPath = $(Split-Path -parent $Script:MyInvocation.MyCommand.Path)
    )

    
    # '[v]alentia' is the same as 'valentia' but $Error is not polluted
    Remove-Module [v]alentia -Force
    Import-Module (Join-Path $scriptPath valentia.psm1) -Force -Verbose

}
