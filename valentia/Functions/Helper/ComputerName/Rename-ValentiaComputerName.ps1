#Requires -Version 3.0

#-- Helper for valentia --#

function Rename-ValentiaComputerName
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param
    (
        [parameter(mandatory = $true, Position  = 0, ValueFromPipeline = 1, ValueFromPipelineByPropertyName = 1)]
        [validateLength(1,15)]
        [string]$NewComputerName,

        [parameter(mandatory = $false, Position  = 1)]
        [switch]$Force,

        [parameter(mandatory = $false, Position  = 2)]
        [switch]$PassThru = $false
    )
   
    end
    {
        # InvalidCharactorCheck
        if ($detect = GetContainsInvalidCharactor -ComputerName $NewComputerName)
        {
            throw ("NewComputerName '{0}' conrains invalid charactor : {1} . Make sure not to include following fault charactors. : {2}" -f $NewComputerName, (($detect | sort -Unique) -join ""), '`~!@#$%^&*()=+_[]{}\|;:.''",<>/?')
        }

        # Execute Change
        $RegistryParam.GetEnumerator() `
        | %{CheckItemProperty -BasePath $_.BasePath -name $_.Name} `
        | where {$force -or $PSCmdlet.ShouldProcess($_.path, ("Change ComputerName on Registry PropertyName : '{1}', CurrentValue : '{2}', NewName : '{3}'" -f $_.path, $_.Property, $_.Value, $NewComputerName))} `
        | %{
            if ($_.Path -eq $HKLMTcpip)
            {
                Write-Verbose ("Removing existing Registry before set new ComputerName. Registry : '{0}'" -f $_.path)
                Remove-ItemProperty -Path $_.path -Name $_.Property
            }

            Write-Verbose ("Setting New ComputerName on Registry : '{0}'" -f $_.path)
            Set-ItemProperty -Path $_.path -Name $_.Property -Value $NewComputerName -PassThru:$passThru
        }
    }

    begin
    {
        Set-StrictMode -Version Latest
        $PSBoundParameters.Remove('Force') > $null
        $list = New-Object 'System.Collections.Generic.List[PSCustomObject]'

        # HostName from Refistry
        Write-Verbose "Obtain Host Names from Registry Keys."
        $HKLMComputerName = "registry::HKLM\SYSTEM\CurrentControlSet\Control\Computername"
        $HKLMTcpip = "registry::HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
        $HKLMWinLogon = "registry::HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
        $HKUWMSDK = "registry::HKU\.Default\Software\Microsoft\Windows Media\WMSDK\General"

        $RegistryParam = (
            @{
                BasePath = "$HKLMComputerName\Computername"
                name     ="Computername"
            },
            @{
                BasePath = "$HKLMComputerName\ActiveComputername"
                name ="Computername"
            },
            @{
                BasePath = $HKLMTcpip
                name     = "Hostname"
            },
            @{
                BasePath = $HKLMTcpip
                name     = "NV Hostname"
            },
            @{
                BasePath = $HKLMWinLogon
                name     = "AltDefaultDomainName"
            },
            @{
                BasePath = $HKLMWinLogon
                name     = "DefaultDomainName"
            },
            @{
                BasePath = $HKUWMSDK
                name     = "Computername"
            }
        )

        function GetContainsInvalidCharactor ([string]$ComputerName)
        {
            $detectedChar = ""
            # Invalid Charactor list described by MS : http://support.microsoft.com/kb/228275
            $invalidCharactor = [System.Linq.Enumerable]::ToArray('`~!@#$%^&*()=+_[]{}\|;:.''",<>/?')
            $detectedChar = [System.Linq.Enumerable]::ToArray($ComputerName) | where {$_ -in $invalidCharactor}
            return $detectedChar
        }

        function CheckItemProperty ([string]$BasePath, [string]$Name)
        {
            $result = $null
            if (Test-Path $BasePath)
            {
                $base = Get-ItemProperty $BasePath
                $keyExist = ($base | Get-Member -MemberType NoteProperty).Name -contains $Name
                if (($null -ne $base) -and $keyExist)
                {
                    Write-Verbose ("Found. Path '{0}' and Name '{1}' found. Show result." -f $BasePath, $Name)
                    $result = [ordered]@{
                        path      = $BasePath
                        Property  = $name
                        value     = ($base | where $Name | %{Get-ItemProperty -path $BasePath -name $Name}).$Name
                    }
                }
                else
                {
                    Write-Verbose ("Skip. Path '{0}' found but Name '{1}' not found." -f $BasePath, $Name)
                }
            }
            else
            {
                Write-Verbose ("Skip. Path '{0}' not found." -f $BasePath)
            }

            if ($null -eq $result)
            {
                Write-Verbose ("Skip. Item Property '{0}' not found from path '{1}'." -f $name, $BasePath)
            }
            else
            {
                return [PSCustomObject]$result
            }
        }
    }
}