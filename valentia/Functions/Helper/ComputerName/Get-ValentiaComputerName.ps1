#Requires -Version 3.0

function Get-ValentiaComputerName
{
    [CmdletBinding(DefaultParameterSetName = 'Registry')]
    param
    (
        [parameter(mandatory = $false, Position  = 0, ParameterSetName = "Registry")]
        [switch]$Registry,

        [parameter(mandatory = $false, Position  = 0, ParameterSetName = "DotNet")]
        [switch]$DotNet
    )
   
    end
    {
        if ($DotNet)
        {
            Write-Verbose "Objain Host Names from Syste.Net.DSC."
            $hostByName = [System.Net.DNS]::GetHostByName('')
            [PSCustomObject]@{
                HostaName = $hostByName.HostName
                IPAddress = $hostByName.AddressList
            }
        }
        else
        {
            $RegistryParam.GetEnumerator() | %{CheckItemProperty -BasePath $_.BasePath -name $_.Name}
        }
    }

    begin
    {
        Set-StrictMode -Version Latest

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