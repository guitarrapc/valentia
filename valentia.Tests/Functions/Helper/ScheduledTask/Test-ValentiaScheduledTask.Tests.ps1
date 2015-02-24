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
    $disable = $true
    $hidden = $true
    $credential = Get-Credential
    $scheduledAt = [datetime]"2015/1/1 0:0:0"

    $param = @{
        Execute = $execute
        TaskName = $taskName
        ScheduledAt = $scheduledAt
        Once = $true
    }
    Set-ValentiaScheduledTask @param -Force $true > $null

    Context "Minimum test for TaskName, Execute, ScheduledAt and Once" {

        It "valid TaskName should not throw" {
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

        It "valid TaskName, Execute, invalid ScheduleAt should return false" {
            Test-ValentiaScheduledTask -TaskName $taskName -Execute $xecute -ScheduledAt $scheduledAt.AddMinutes(1) | should be $false
        }

        It "valid TaskName, Execute, ScheduleAt, invalid Once should return false" {
            Test-ValentiaScheduledTask -TaskName $taskName -Execute $xecute -ScheduledAt $scheduledAt -Once $false | should be $false
        }
    }

    Remove-ValentiaScheduledTask -taskName $taskName -Force $true > $null

    $param = @{
        TaskName = $taskName
        Execute = $execute
        ScheduledAt = $scheduledAt
        Daily = $true
        Argument = $argument
        WorkingDirectory = $workingDirectory
        Description = $description
        TaskPath = $taskPath
        Disable = $disable
        Hidden = $hidden
        Credential = $credential
    }
    Set-ValentiaScheduledTask @param -Force $true > $null

    Context "complex test for TaskName, Execute, ScheduledAt and Daily" {

        It "valid TaskName, Execute, ScheduledAt, Daily, Argument should return true" {
            Test-ValentiaScheduledTask -TaskName $taskName -Execute $execute -ScheduledAt $scheduledAt -Daily $true -Argument $argument | should be $true
        }

        It "valid TaskName, Execute, ScheduledAt, Daily, Argument, WorkingDirectory should return true" {
            Test-ValentiaScheduledTask -TaskName $taskName -Execute $execute -ScheduledAt $scheduledAt -Daily $true -Argument $argument -WorkingDirectory $workingDirectory | should be $true
        }

        It "valid TaskName, Execute, ScheduledAt, Daily, Argument, WorkingDirectory, Description should return true" {
            Test-ValentiaScheduledTask -TaskName $taskName -Execute $execute -ScheduledAt $scheduledAt -Daily $true -Argument $argument -WorkingDirectory $workingDirectory -Description $description | should be $true
        }

        It "valid TaskName, Execute, ScheduledAt, Daily, Argument, WorkingDirectory, Description, TaskPath should return true" {
            Test-ValentiaScheduledTask -TaskName $taskName -Execute $execute -ScheduledAt $scheduledAt -Daily $true -Argument $argument -WorkingDirectory $workingDirectory -Description $description -TaskPath $taskPath | should be $true
        }

        It "valid TaskName, Execute, ScheduledAt, Daily, Argument, WorkingDirectory, Description, TaskPath, Disable should return true" {
            Test-ValentiaScheduledTask -TaskName $taskName -Execute $execute -ScheduledAt $scheduledAt -Daily $true -Argument $argument -WorkingDirectory $workingDirectory -Description $description -TaskPath $taskPath -Disable $disable | should be $true
        }

        It "valid TaskName, Execute, ScheduledAt, Daily, Argument, WorkingDirectory, Description, TaskPath, Disable, Hidden should return true" {
            Test-ValentiaScheduledTask -TaskName $taskName -Execute $execute -ScheduledAt $scheduledAt -Daily $true -Argument $argument -WorkingDirectory $workingDirectory -Description $description -TaskPath $taskPath -Disable $disable -Hidden $hidden | should be $true
        }

        It "valid TaskName, Execute, ScheduledAt, Daily, Argument, WorkingDirectory, Description, TaskPath, Disable, Hidden, Credential should return true" {
            Test-ValentiaScheduledTask -TaskName $taskName -Execute $execute -ScheduledAt $scheduledAt -Daily $true -Argument $argument -WorkingDirectory $workingDirectory -Description $description -TaskPath $taskPath -Disable $disable -Hidden $hidden -Credential $credential | should be $true
        }

        It "valid TaskName, Execute, ScheduledAt, invalid Daily should return false" {
            Test-ValentiaScheduledTask -TaskName $taskName -Execute $execute -ScheduledAt $scheduledAt -Daily $false | should be $false
        }

        It "valid TaskName, Execute, ScheduledAt, Daily, invalid Argument should return false" {
            Test-ValentiaScheduledTask -TaskName $taskName -Execute $execute -ScheduledAt $scheduledAt -Daily $true -Argument "hoge" | should be $false
        }

        It "valid TaskName, Execute, ScheduledAt, Daily, Argument, invalid WorkingDirectory should return false" {
            Test-ValentiaScheduledTask -TaskName $taskName -Execute $execute -ScheduledAt $scheduledAt -Daily $true -Argument $argument -WorkingDirectory "hoge" | should be $false
        }

        It "valid TaskName, Execute, ScheduledAt, Daily, Argument, WorkingDirectory, invalid Description should return false" {
            Test-ValentiaScheduledTask -TaskName $taskName -Execute $execute -ScheduledAt $scheduledAt -Daily $true -Argument $argument -WorkingDirectory $workingDirectory -Description fuga | should be $false
        }

        It "valid TaskName, Execute, ScheduledAt, Daily, Argument, WorkingDirectory, Description, invalid TaskPath should return false" {
            Test-ValentiaScheduledTask -TaskName $taskName -Execute $execute -ScheduledAt $scheduledAt -Daily $true -Argument $argument -WorkingDirectory $workingDirectory -Description $description -TaskPath \fuga\ | should be $false
        }

        It "valid TaskName, Execute, ScheduledAt, Daily, Argument, WorkingDirectory, Description, TaskPath, invalid Disable should return false" {
            Test-ValentiaScheduledTask -TaskName $taskName -Execute $execute -ScheduledAt $scheduledAt -Daily $true -Argument $argument -WorkingDirectory $workingDirectory -Description $description -TaskPath $taskPath -Disable $false | should be $false
        }

        It "valid TaskName, Execute, ScheduledAt, Daily, Argument, WorkingDirectory, Description, TaskPath, Disable, invalid Hidden should return false" {
            Test-ValentiaScheduledTask -TaskName $taskName -Execute $execute -ScheduledAt $scheduledAt -Daily $true -Argument $argument -WorkingDirectory $workingDirectory -Description $description -TaskPath $taskPath -Disable $disable -Hidden $false | should be $false
        }

        It "valid TaskName, Execute, ScheduledAt, Daily, Argument, WorkingDirectory, Description, TaskPath, Disable, Hidden, invalid Credential should return true" {
            Test-ValentiaScheduledTask -TaskName $taskName -Execute $execute -ScheduledAt $scheduledAt -Daily $true -Argument $argument -WorkingDirectory $workingDirectory -Description $description -TaskPath $taskPath -Disable $disable -Hidden $hidden -Credential (Get-Credential) | should be $false
        }
    }

    Remove-ValentiaScheduledTask -taskName $taskName -taskPath $taskPath -Force $true > $null
}
