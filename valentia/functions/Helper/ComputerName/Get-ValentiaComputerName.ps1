#Requires -Version 3.0

function Get-ValentiaComputerName
{
    [CmdletBinding(DefaultParameterSetName = 'Registry')]
    param
    (
        [parameter(
            Mandatory = 0,
            Position  = 0,
            ParameterSetName = "Registry")]
        [switch]
        $Registry,

        [parameter(
            Mandatory = 0,
            Position  = 0,
            ParameterSetName = "DotNet")]
        [switch]
        $DodNet
    )
   
    end
    {
        if ($DodNet)
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
            Write-Verbose "Objain Host Names from Registry Keys."
            $HKLMComputerName = "registry::HKLM\SYSTEM\CurrentControlSet\Control\Computername"
            $HKLMTcpip = "registry::HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
            $HKLMWinLogon = "registry::HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
            $HKUWMSDK = "registry::HKU\.Default\Software\Microsoft\Windows Media\WMSDK\General"

            CheckItemProperty -BasePath "$HKLMComputerName\Computername" -name "Computername"
            CheckItemProperty -BasePath "$HKLMComputerName\ActiveComputername" -name "Computername"

            CheckItemProperty -BasePath $HKLMTcpip -name "Hostname"
            CheckItemProperty -BasePath $HKLMTcpip -name "NV Hostname"

            CheckItemProperty -BasePath $HKLMWinLogon -name "AltDefaultDomainName"
            CheckItemProperty -BasePath $HKLMWinLogon -name "DefaultDomainName"

            CheckItemProperty -BasePath $HKUWMSDK -name "Computername"
        }
    }

    begin
    {
        Set-StrictMode -Version Latest
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