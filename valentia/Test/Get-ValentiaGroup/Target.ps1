#Requires -Version 3.0

Import-Module Valentia -Force
$Host.UI.WriteLine("Function Test")
$deploygroup = Get-ValentiaGroup 127.0.0.1
$deploygroup

$Host.UI.WriteLine("Alias Test")
$alias = target 127.0.0.1, 127.0.0.1
$alias