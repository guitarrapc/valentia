#Requires -Version 3.0

Import-Module Valentia -Force
$deploygroup = target 127.0.0.1
Ping-ValentiaGroupAsync -HostNameOrAddresses $deploygroup