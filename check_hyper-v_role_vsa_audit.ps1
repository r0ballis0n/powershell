# Set Execution Policy
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

# Check if Hyper-V role is installed
$HyperVRole = Get-WindowsFeature -Name Hyper-V

# Specify the output file
$OutputFile = "c:\temp\hyperVCheckResult.txt"

# Check if the Hyper-V role is installed and write 'yes' to the output file
if ($HyperVRole.InstallState -eq "Installed") {
    "Yes" | Set-Content -Path $OutputFile
} else {
    "No" | Set-Content -Path $OutputFile
}
