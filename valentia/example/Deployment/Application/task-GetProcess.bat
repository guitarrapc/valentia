@echo off

:// Set TaskName (Just Change Here for new task execution.)
set TaskFile=task-GetProcess.ps1

:// Get Argument and set to DeproyGroup Name
set /p DeployGroup=Input DeployGroup:

if "%DeployGroup%" == "" echo "Argument was empty. Please specify DeployGroup!" && pause && exit
echo "Deploy Group sat as %DeployGroup%"


:// # Asynchronous MultiThread
powershell -Command "valea %DeployGroup% .\%TaskFile% -Verbose"

:// # Parallel Single thread
REM powershell -Command "valep %DeployGroup% .\%TaskFile% -Verbose"

:// # Synchronous Job
powershell -Command "vale %DeployGroup% .\%TaskFile% -Verbose"

