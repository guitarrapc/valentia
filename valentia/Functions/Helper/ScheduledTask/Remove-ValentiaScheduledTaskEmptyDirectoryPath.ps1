#Requires -Version 3.0

#-- Scheduler Task Functions --#

<#
.SYNOPSIS 
Extension to set TaskScheduler and Remove Task folder where Task not exist

.DESCRIPTION
You can remove task Empty folder. Normal Unregister Cmdlet never erase them and it may cause some issue like TaskScheduler could not name as same as child folder of TaskPath.

You can not create hoge task in root (\) when there are \hoge\ folder.

\
 -> \hoge\
 -> \Microsoft\


.NOTES
Author: guitarrapc
Created: 24/Sep/2014

.EXAMPLE
$param = @{
    taskName          = "hoge"
    Description       = "None"
    taskPath          = "\fuga"
    execute           = "powershell.exe"
    Argument          = '-Command "Get-Date | out-File c:\task01.log"'
    ScheduledAt       = [datetime]"00:30:00"
    Once              = $true
    Hidden            = $true
    Disable           = $false
    Force             = $true
    Runlevel          = "limited"
}
Set-ValentiaScheduledTask @param
Remove-ValentiaScheduledTask -taskName $param.taskName -taskPath $param.taskPath
Remove-ValentiaScheduledTaskEmptyDirectoryPath

# Remove task not exist any task or taskfolder.

.LINK
https://github.com/guitarrapc/valentia/wiki/TaskScheduler-Automation

#>

function Remove-ValentiaScheduledTaskEmptyDirectoryPath
{
    # validate target Directory is existing
    $path = Join-Path $env:windir "System32\Tasks"
    $result = Get-ChildItem -Path $path -Directory | where Name -ne "Microsoft"
    if (($result | measure).count -eq 0){ return; }

    # validate Child is blank
    $result.FullName `
    | where {(Get-ChildItem -Path $_) -eq $null} `
    | Remove-Item -Force
}