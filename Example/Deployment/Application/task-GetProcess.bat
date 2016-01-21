@echo off
set execute=execute\execute.ps1
set TaskFile=%~n0.ps1
powershell -Command %execute% -taskFile %TaskFile%