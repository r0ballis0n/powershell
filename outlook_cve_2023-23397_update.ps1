# Office CVE2023-23397 Update Script

# Set Execution Policy
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

# Log Location Variable
$logFile = "C:\tmp\outlook_cve202323397_script.log"

# Function to write logs to a log file
function Write-Log($message) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp $message" | Out-File -FilePath $logFile -Append
}

#Install PSWindowsUpdate PowerShell module if needed
try {   
    if (!(Get-Module -Name PSWindowsUpdate -ListAvailable)) {
        Write-Log "PSWindowsUpdate module not found. Installing module..."
        Install-Module -Name PSWindowsUpdate -Scope AllUsers -Force
        Import-Module -Name PSWindowsUpdate
        Write-Log "PSWindowsUpdate module installed"
    } else {
        Write-Log "PSWindowsUpdate module already installed."
    }
} catch {
    Write-Log "Error installing PSWindowsUpdate module: $_"
}

# Check for Office Click-To-Run Products
try {
    $officeC2R = Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*,HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "*Microsoft Office Professional Plus 2019*" -or $_.DisplayName -like "*Microsoft Office Professional Plus 2021*" -or $_.DisplayName -like "*Microsoft Office 365*" -or $_.DisplayName -like "*Microsoft 365*"}
    if ($null -ne $officeC2R) {
        if (Test-Path "C:\Program Files\Common Files\microsoft shared\ClickToRun\OfficeC2RClient.exe") {
            Write-Log "Click-To-Run Office detected. Initiating update."
            & "C:\Program Files\Common Files\microsoft shared\ClickToRun\OfficeC2RClient.exe" /update user displaylevel=false forceappshutdown=true
            Write-Log "Click-To-Run Office update complete."
        }
        else {
            Write-Log "No Click-To-Run Office detected."
        }
    }
} catch {
    Write-Log "Error updating Click-To-Run Office: $_"
}

 # Temporarily disable WSUS
 try {
    $wsusRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
    if (Test-Path $wsusRegPath) {
        $wsusValue = Get-ItemPropertyValue -Path $wsusRegPath -Name UseWUServer -ErrorAction Stop
        if ($null -ne $wsusValue) {
            Write-Log "Disabling WSUS"
            Set-ItemProperty -Path $wsusRegPath -Name UseWUServer -Value 0
        } else {
            Write-Log "UseWUServer property not found in WSUS registry key."
        }
    } else {
        Write-Log "WSUS registry key not found."
    }
} catch {
    if ($_.Exception.Message -match "Property UseWUServer does not exist") {
        Write-Log "UseWUServer property not found in WSUS registry key."
    } else {
        Write-Log "Error disabling WSUS: $_"
    }
}

# Temporarily disable Windows Update for Business deferral period
try {
    $wufbRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
    if (Test-Path $wufbRegPath) {
        $wufbValue = (Get-ItemProperty -Path $wufbRegPath -Name DeferQualityUpdatesPeriodInDays -ErrorAction SilentlyContinue).DeferQualityUpdatesPeriodInDays
        if ($null -ne $wufbValue) {
            Write-Log "Disabling Windows Update for Business deferral period"
            Set-ItemProperty -Path $wufbRegPath -Name DeferQualityUpdatesPeriodInDays -Value 0
        }
    } else {
        Write-Log "Windows Update for Business registry key not found."
    }
} catch {
    Write-Log "Error disabling Windows Update for Business deferral period: $_"
}


# Check if Office 2013 is installed and if the KB5002265 update is installed
try {
if ($null -ne $office2013) {
    $KB5002265_installed = Get-WindowsUpdate -KBArticleID KB5002265 -IsInstalled
    if (!$KB5002265_installed) {
        Write-Log "Installing KB5002265 for Office 2013"
        Install-WindowsUpdate -KBArticleID KB5002265 -MicrosoftUpdate -IgnoreReboot -Verbose -Confirm:$false
        Write-Log "KB5002265 Installed"
    }
    else {
        Write-Log "Outlook 2013 CVE-2023-23397 Vulnerability Not Found"
    }
}

# Check if Office 2016 is installed and if the KB5002254 update is installed
if ($null -ne $office2016) {
    $KB5002254_installed = Get-WindowsUpdate -KBArticleID KB5002254 -IsInstalled

    # If the KB5002254 update is not installed, install it
    if (!$KB5002254_installed) {
        Write-Log "Installing KB5002254 for Office 2016"
        Install-WindowsUpdate -KBArticleID KB5002254 -MicrosoftUpdate -IgnoreReboot -Verbose -Confirm:$false
        Write-Log "KB5002254 Installed"
    }
    else {
        Write-Log "No Outlook 2016 CVE-2023-23397 vulnerability"
    }
}
} catch {
Write-Log "Error installing Office 2013/2016 updates: $_"
}

# Return UseWUServer to previous value
try {
if ($null -ne $wsusValue) {
    Write-Log "Enabling WSUS"
    Set-ItemProperty -Path $wsusRegPath -Name UseWUServer -Value $wsusValue
}
} catch {
Write-Log "Error enabling WSUS: $_"
}

# Return DeferQualityUpdatesPeriodInDays to previous value
try {
if ($null -ne $wufbValue) {
    Write-Log "Enabling Windows Update for Business deferral period"
    Set-ItemProperty -Path $wufbRegPath -Name DeferQualityUpdatesPeriodInDays -Value $wufbValue
}
} catch {
Write-Log "Error enabling Windows Update for Business deferral period: $_"
}

Write-Log "Update complete if reboot is needed system will do it now."

# Reboot if any pending updates
try {
Get-WURebootStatus -AutoReboot
} catch {
Write-Log "Error checking for pending updates and reboot: $_"
}

#End
