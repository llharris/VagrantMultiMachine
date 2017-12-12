$domainName = $args[0]
$netbiosDomainName = $args[1]
$SMAPasswordPlain = $args[2]
$SMAPasswordSecure = $SMAPasswordPlain | ConvertTo-SecureString -AsPlainText -Force
$network = $args[3]
$linode_count = $args[4]
$winode_count = $args[5]
$DomainAdminPasswordPlain = $args[6]
$DomainAdminPasswordSecure = $DomainAdminPasswordPlain | ConvertTo-SecureString -AsPlainText -Force
 
Set-WinUserLanguageList -LanguageList en-GB -Force
Install-WindowsFeature AD-Domain-Services
Install-WindowsFeature RSAT-AD-Tools

$InstallADDSForestParams = @{
    CreateDNSDelegation = $false;
    DatabasePath = "C:\Windows\NTDS";
    DomainMode = "Win2012R2";
    DomainName = "$domainName";
    DomainNetbiosName = "$netbiosDomainName";
    ForestMode = "Win2012R2";
    InstallDns = $true;
    LogPath = "C:\Windows\NTDS";
    NoRebootOnCompletion = $true;
    SysvolPath = "C:\Windows\SYSVOL";
    SafeModeAdministratorPassword = $SMAPasswordSecure;
    Force = $true
}

Install-ADDSForest @InstallADDSForestParams
Set-AdAccountPassword administrator -NewPassword $DomainAdminPasswordSecure -Reset

Add-DnsServerResourceRecordA -Name "master" -ZoneName $domainName -IPv4Address "$network.10"

if ( $linode_count -gt 0 ) {
    for($l=1; $l -le $linode_count; $l++) {
        $last_octet = ($l+10)
        Add-DnsServerResourceRecordA -Name "linux$l" -ZoneName $domainName -IPv4Address "$network.$last_octet"
        }
    }

if ( $winode_count -gt 0 ) {
    for($w=1; $w -le $winode_count; $w++) {
        $last_octet = ($w+100)
        Add-DnsServerResourceRecordA -Name "win$w" -ZoneName $domainName -IPv4Address "$network.$last_octet"
        }
    }   
    
    
    
