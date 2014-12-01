#Requires -Version 3.0

#-- Public Class load for Asynchronous execution (MultiThread) --#
Add-Type @'
public class AsyncPipeline
{
    public System.Management.Automation.PowerShell Pipeline ;
    public System.IAsyncResult AsyncResult ;
}
'@

#-- PublicEnum for CredRead/Write Type --#
Add-Type -TypeDefinition @"
    public enum ValentiaWindowsCredentialManagerType
    {
        Generic           = 1,
        DomainPassword    = 2,
        DomainCertificate = 3
    }
"@

#-- PublicEnum for Location Type --#
Add-Type -TypeDefinition @"
    public enum ValentiaBranchPath
    {
        Application       = 1,
        Deploygroup       = 2,
        Download          = 3,
        Maintenance       = 4,
        Upload            = 5,
        Utils             = 6
    }
"@
# file loaded from path : \type\Type.ps1

