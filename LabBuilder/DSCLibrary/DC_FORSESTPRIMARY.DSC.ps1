<#########################################################################################################################################
DSC Template Configuration File For use by LabBuilder
.Title
	DC_FORESTPRIMARY
.Desription
	Builds a Domain Controller as the first DC in a forest with the name of the Domain Name parameter passed.
.Parameters:          
	DomainName = "BMDLAB.COM"
	DomainAdminPassword = "P@ssword!1"
#########################################################################################################################################>

Configuration DC_FORESTPRIMARY
{
	Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
	Import-DscResource -ModuleName xActiveDirectory
	Node $AllNodes.NodeName {
		# Assemble the Local Admin Credentials
		If ($Node.LocalAdminPassword) {
			[PSCredential]$LocalAdminCredential = New-Object System.Management.Automation.PSCredential ("Administrator", (ConvertTo-SecureString $Node.LocalAdminPassword -AsPlainText -Force))
		}
		If ($Node.DomainAdminPassword) {
			[PSCredential]$DomainAdminCredential = New-Object System.Management.Automation.PSCredential ("Administrator", (ConvertTo-SecureString $Node.DomainAdminPassword -AsPlainText -Force))
		}

		WindowsFeature DNSInstall 
        { 
            Ensure = "Present" 
            Name = "DNS" 
        } 

		WindowsFeature ADDSInstall 
        { 
            Ensure = "Present" 
            Name = "AD-Domain-Services" 
			DependsOn = "[WindowsFeature]DNSInstall" 
        } 
		
		WindowsFeature RSAT-AD-PowerShellInstall
		{
			Ensure = "Present"
			Name = "RSAT-AD-PowerShell"
			DependsOn = "[WindowsFeature]ADDSInstall" 
		}

        xADDomain PrimaryDC 
        { 
            DomainName = $Node.DomainName 
            DomainAdministratorCredential = $DomainAdminCredential 
            SafemodeAdministratorPassword = $LocalAdminCredential 
            DependsOn = "[WindowsFeature]ADDSInstall" 
        } 

        xWaitForADDomain DscForestWait 
        { 
            DomainName = $Node.DomainName 
            DomainUserCredential = $DomainAdminCredential 
            RetryCount = 20 
            RetryIntervalSec = 30 
            DependsOn = "[xADDomain]PrimaryDC" 
        } 
		
		xADRecycleBin RecycleBin
        {
			EnterpriseAdministratorCredential = $DomainAdminCredential
			ForestFQDN = $Node.DomainName
		    DependsOn = "[xWaitForADDomain]DscForestWait"
        }
	}
}