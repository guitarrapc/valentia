#Requires -Version 3.0

function Add-ValentiaTypeMemberDefinition
{
    [CmdletBinding()]
    param
    (
        [Parameter(mandatory = $true, position = 0)]
        [string]$MemberDefinition,

        [Parameter(mandatory = $true, position = 1)]
        [string]$NameSpace,

        [Parameter(mandatory = $false, position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(mandatory = $false, position = 3)]
        [ValidateNotNullOrEmpty()]
        [string[]]$UsingNameSpace,

        [Parameter(mandatory = $false, position = 4)]
        [switch]$PassThru
    )

    $private:guid = [Guid]::NewGuid().ToString().Replace("-", "_")
    $private:addType = @{
        MemberDefinition = $MemberDefinition
        Namespace        = $NameSpace 
        Name             = $Name + $guid
    }

    if (($UsingNameSpace | measure).Count -ne 0)
    {
        $addType.UsingNameSpace = $UsingNameSpace
    }

    $private:result = Add-Type @addType -PassThru
    if ($PassThru)
    {
        return $result
    }
}