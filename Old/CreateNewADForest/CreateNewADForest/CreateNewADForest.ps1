Configuration CreateNewADForest {
param
    #v1.4
   ( 
        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$AdminCreds,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$SafeModeAdminCreds,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$myFirstUserCreds,

        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=30
    )

    


    #Import-DscResource -ModuleName xActiveDirectory, xNetworking, xPendingReboot

    Import-DscResource -ModuleName @{ModuleName="xActiveDirectory";ModuleVersion="2.16.0.0"}, @{ModuleName="xNetworking";ModuleVersion="2.4.0.0"}, @{ModuleName="xPendingReboot";ModuleVersion="0.1.0.2"}

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)

    Node localhost
    {
        LocalConfigurationManager            
        {            
            ActionAfterReboot = 'ContinueConfiguration'            
            ConfigurationMode = 'ApplyOnly'            
            RebootNodeIfNeeded = $true            
        } 

        WindowsFeature DNS 
        { 
            Ensure = "Present" 
            Name = "DNS"
        }


        WindowsFeature RSAT
        {
            Ensure = "Present"
            Name = "RSAT"
        }

        WindowsFeature ADDSInstall 
        { 
            Ensure = "Present" 
            Name = "AD-Domain-Services"
        }  

        xADDomain FirstDC 
        {
            DomainName = $DomainName
            DomainAdministratorCredential = $DomainCreds
            SafemodeAdministratorPassword = $DomainCreds
            DatabasePath = "C:\NTDS"
            LogPath = "C:\NTDS"
            SysvolPath = "C:\SYSVOL"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        xWaitForADDomain DscForestWait
        {
            DomainName = $DomainName
            DomainUserCredential = $DomainCreds
            RetryCount = $RetryCount
            RetryIntervalSec = $RetryIntervalSec
            DependsOn = "[xADDomain]FirstDC"
        } 

        xADUser FirstUser 
        { 
            DomainName = $DomainName 
            DomainAdministratorCredential = $DomainCreds 
            UserName = $myFirstUserCreds.Username 
            Password = $myFirstUserCreds
            Ensure = "Present" 
            DependsOn = "[xWaitForADDomain]DscForestWait" 
        } 

        xPendingReboot Reboot1
        { 
            Name = "RebootServer"
            DependsOn = "[xWaitForADDomain]DscForestWait"
        }

   }
}