$NtpServer = "0.pool.ntp.org"
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters"
New-ItemProperty -Path $RegistryPath -Name "NtpServer" -Value $NtpServer -PropertyType "String" -Force | Out-Null
Stop-Service w32time
Start-Service w32time
