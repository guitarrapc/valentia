# Read Me Fast
All the valentia functions will be locate here.

# Add functions file
You can add functions into this directory.
 
# Export function as valentia cmdlet
All you need is add function name inside .psd1 and valentia.ps1. Both will created by executing ```build.ps1```.

So the way you add functions inside valentia module is....

1. Add function you want inside valentia\functions.
2. If you want to set Alias for the function, then add Alias inside valentia.psm1.
3. Add functions name in ```Tools/build.ps1```.
4. add Alias name in ```Tools/build.ps1```.
5. run the ```Tools/build.ps1``` as PowerShell. then valentia.psd1 and valentia.ps1 will be generated.