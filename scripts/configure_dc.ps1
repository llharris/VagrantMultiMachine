$domainName = $args[0]
$netbiosDomainName = $args[1]
$SMAPasswordPlain = $args[2]
$SMAPasswordSecure = $SMAPasswordPlain | ConvertTo-SecureString -AsPlainText -Force
$network = $args[3]
$linode_count = $args[4]
$winode_count = $args[5]
$language = $args[6]

Write-Host "Setting language $language"
Set-WinUserLanguageList -LanguageList $language -Force
Write-Host "Installing Windows Feature AD-Domain-Services"
Install-WindowsFeature AD-Domain-Services
Write-Host "Installing Windows Feature RSAT-AD-Tools"
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

Write-Host "Configuring AD Forest"
Install-ADDSForest @InstallADDSForestParams

Write-Host "Creating DNS Records"
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

Write-Host "Rearming evaluation Licence"
slmgr.vbs -rearm
    
Write-Host "Rebooting in 30 seconds..."
shutdown -t 30 -r -f
    
    
