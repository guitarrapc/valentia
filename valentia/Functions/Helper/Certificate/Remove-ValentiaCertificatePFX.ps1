#Requires -Version 3.0

#-- Helper for certificate --#

function Remove-ValentiaCertificatePFX
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory = 0, position  = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$CN = $valentia.certificate.CN,

        [parameter(mandatory = 0, position  = 1, ValueFromPipeline = 1, ValueFromPipelineByPropertyName = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$PFXFilePath = $valentia.certificate.FilePath.PFX,

        [parameter(mandatory = 0, position  = 2)]
        [switch]$force = $false
    )
    
    $param = @{
        Path    = $PFXFilePath -f $CN
        Confirm = (-not $force)
        Force   = $force
    }
    if (Test-Path $param.Path)
    {
        Remove-Item @param
    }
}