$network = $args[0]
$language = $args[1]

Write-Host "Setting language $language"
Set-WinUserLanguageList -LanguageList $language -Force

Write-Host "Setting DNS server IP to $network.10"
netsh interface ip set dns "Ethernet 2" static "$network.10"