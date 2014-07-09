#Requires -Version 3.0

#-- Helper for valentia --#

function Set-ValentiaComputerName
{
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact         = 'High')]
    param
    (
        [parameter(
            Mandatory = 1,
            Position  = 0)]
        [string]
        $NewComputerName,

        [parameter(
            Mandatory = 0,
            Position  = 1)]
        [switch]
        $Force,

        [parameter(
            Mandatory = 0,
            Position  = 2)]
        [switch]
        $PassThru = $false
    )
   
    end
    {
        $RegistryParam.GetEnumerator() `
        | %{CheckItemProperty -BasePath $_.BasePath -name $_.Name `
        | where {$force -or $PSCmdlet.ShouldProcess($_.path, ("Change ComputerName on Registry PropertyName : '{1}', CurrentValue : '{2}', NewName : '{3}'" -f $_.path, $_.Property, $_.Value, $NewComputerName))} `
        | %{
            if ($_.Path -eq $HKLMTcpip)
            {
                Write-Verbose ("Removing existing Registry before set new ComputerName. Registry : '{0}'" -f $_.path)
                Remove-ItemProperty -Path $_.path -Name $_.Property
            }

            Write-Verbose ("Setting New ComputerName on Registry : '{0}'" -f $_.path)
            Set-ItemProperty -Path $_.path -Name $_.Property -Value $NewComputerName -PassThru:$passThru}
        }
    }

    begin
    {
        Set-StrictMode -Version Latest
        $list = New-Object 'System.Collections.Generic.List[PSCustomObject]'
        $PSBoundParameters.Remove('Force') > $null


        # HostName from Refistry
        Write-Verbose "Objain Host Names from Registry Keys."
        $HKLMComputerName = "registry::HKLM\SYSTEM\CurrentControlSet\Control\Computername"
        $HKLMTcpip = "registry::HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
        $HKLMWinLogon = "registry::HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
        $HKUWMSDK = "registry::HKU\.Default\Software\Microsoft\Windows Media\WMSDK\General"

        $RegistryParam = (
            @{
                BasePath = "$HKLMComputerName\Computername"
                name     ="Computername"
            },
                @{BasePath = "$HKLMComputerName\ActiveComputername"
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