$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")

. "$here\$sut"

Describe "Test-ValentiaScheduledTask" {

    Import-Module valentia -Force

    $taskName = "fuga"
    $execute = "powershell.exe"
    $argument = "-Command ''"
    $workingDirectory = ""
    $description = "hoge"
    $taskPath = "\hoge\"
    $disabled = $true
    $hidden = $true
    $credential = Get-Credential
    $scheduledAt = [datetime]"2015/1/1 0:0:0"

    $param = @{
        Execute = $execute
        TaskName = $taskName
        ScheduledAt = $scheduledAt
        Once = $true
    }
    Set-ValentiaScheduledTask @param -Force $true

    Context "Minimum test for TaskName, Execute, ScheduledAt and Once" {

        It "Only checking valid TaskName should not throw" {
            {Test-ValentiaScheduledTask -TaskName $taskName -Execute $execute} | should not Throw
        }

        It "valid TaskName, Execute should return true" {
            Test-ValentiaScheduledTask -TaskName $taskName -Execute $execute | should be $true
        }

        It "valid TaskName, Execute, ScheduledAt should return true" {
            Test-ValentiaScheduledTask -TaskName $taskName -Execute $execute -ScheduledAt $scheduledAt | should be $true
        }

        It "valid TaskName, Execute, ScheduledAt, Once should return true" {
            Test-ValentiaScheduledTask -TaskName $taskName -Execute $execute -ScheduledAt $scheduledAt -Once $true | should be $true
        }

        It "invalid TaskName, valid Execute should return false" {
            Test-ValentiaScheduledTask -TaskName hogemoge -Execute $execute | should be $false
        }

        It "valid TaskName, invalid Execute should return false" {
            Test-ValentiaScheduledTask -TaskName $taskName -Execute hogemoge | should be $false
        }

        It "valid TaskName, valid Execute, invalid ScheduleAt should return false" {
            Test-ValentiaScheduledTask -TaskName $taskName -Execute $xecute -ScheduledAt $scheduledAt.AddMinutes(1) | should be $false
        }

        It "valid TaskName, valid Execute, valid ScheduleAt, not Once but Daily should return false" {
            Test-ValentiaScheduledTask -TaskName $taskName -Execute $xecute -ScheduledAt $scheduledAt -Daily $true | should be $false
        }
    }

    Remove-ValentiaScheduledTask -taskName $taskName

    $param = @{
        Execute = $execute
        Argument = $argument
        WorkingDirectory = $workingDirectory
        Description = $description
        TaskName = $taskName
        TaskPath = $taskPath
        ScheduledAt = $scheduledAt
        Once = $true
        Disable = $disabled
        Hidden = $hidden
        Credential = $credential
    }
    Set-ValentiaScheduledTask @param -Force $true

    Context "complex test for TaskName, Execute, ScheduledAt and Once" {

        It "Only checking valid TaskName should not throw" {
            {Test-ValentiaScheduledTask -TaskName $taskName -Execute $execute} | should not Throw
        }

        It "valid TaskName, Execute should return true" {
            Test-ValentiaScheduledTask -TaskName $taskName -Execute $execute | should be $true
        }

        It "valid TaskName, Execute, ScheduledAt should return true" {
            Test-ValentiaScheduledTask -TaskName $taskName -Execute $execute -ScheduledAt $scheduledAt | should be $true
        }

        It "valid TaskName, Execute, ScheduledAt, Once should return true" {
            Test-ValentiaScheduledTask -TaskName $taskName -Execute $execute -ScheduledAt $scheduledAt -Once $true | should be $true
        }

        It "invalid TaskName, valid Execute should return false" {
            Test-ValentiaScheduledTask -TaskName hogemoge -Execute $execute | should be $false
        }

        It "valid TaskName, invalid Execute should return false" {
            Test-ValentiaScheduledTask -TaskName $taskName -Execute hogemoge | should be $false
        }

        It "valid TaskName, valid Execute, invalid ScheduleAt should return false" {
            Test-ValentiaScheduledTask -TaskName $taskName -Execute $xecute -ScheduledAt $scheduledAt.AddMinutes(1) | should be $false
        }

        It "valid TaskName, valid Execute, valid ScheduleAt, not Once but Daily should return false" {
            Test-ValentiaScheduledTask -TaskName $taskName -Execute $xecute -ScheduledAt $scheduledAt -Daily $true | should be $false
        }
    }

    Remove-ValentiaScheduledTask -taskName $taskName -taskPath $taskPath
}
