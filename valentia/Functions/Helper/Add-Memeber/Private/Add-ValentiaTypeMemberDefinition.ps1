#Requires -Version 3.0

function Add-ValentiaTypeMemberDefinition
{
    [CmdletBinding()]
    param
    (
        [Parameter(mandatory = 1, position = 0)]
        [string]$MemberDefinition,

        [Parameter(mandatory = 1, position = 1)]
        [string]$NameSpace,

        [Parameter(mandatory = 0, position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(mandatory = 0, position = 3)]
        [ValidateNotNullOrEmpty()]
        [string[]]$UsingNameSpace,

        [Parameter(mandatory = 0, position = 4)]
        [switch]$PassThru
    )

    $private:guid = [Guid]::NewGuid().ToString().Replace("-", "_")
    $private:addType = @{
        MemberDefinition = $MemberDefinition
        Namespace        = $NameSpace 
        Name             = $Name + $guid
    }
    if (@($UsingNameSpace).Count -ne 0)
    {
        $addType.UsingNameSpace = $UsingNameSpace
    }

    $private:result = Add-Type @addType -PassThru
    if ($PSBoundParameters.PassThru.IsPresent)
    {
        return $result
    }
}