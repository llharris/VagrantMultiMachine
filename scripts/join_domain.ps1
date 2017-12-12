$domainName = $args[0]
$netbiosDomainName = $args[1]
$network = $args[2]
$language = $args[3]
$computername = HOSTNAME.EXE

Write-Host "Setting language $language"
Set-WinUserLanguageList -LanguageList $language -Force

Write-Host "Setting DNS server IP to $network.9"
netsh interface ip set dns "Ethernet 2" static "$network.9"

Write-Host "Joining domain $domainName as $computername using account $netbiosDomainName\administrator"
netdom join /d:"$domainName" "$computername" /ud:"$netbiosDomainName\administrator" /pd:vagrant

Write-Host "Reset licence eval period"
slmgr.vbs -rearm
