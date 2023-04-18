$uptime = (Get-Date) - (gcim Win32_OperatingSystem).LastBootUpTime
$uptimeDays = $uptime.TotalDays

if ($uptimeDays -gt 14) {
    Restart-Computer -Force
}
