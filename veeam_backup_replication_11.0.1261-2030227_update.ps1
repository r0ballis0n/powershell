# Set Execution Policy
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

# Log Location Variable (CHANGE ME)
$logFile = "C:\logdirectory\veeam_patch_script.log"

# Function to write logs to a log file
function Write-Log($message) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp $message" | Out-File -FilePath $logFile -Append
}

#Get Veeam Version -> Write To Variable & Log
try {
    Write-Log "Getting Veeam version..."
    $InstallPath = Get-ItemProperty -Path "HKLM:\Software\Veeam\Veeam Backup and Replication" | Select-Object -ExpandProperty CorePath
    Add-Type -LiteralPath "$InstallPath\Veeam.Backup.Configuration.dll"
    $ProductData = [Veeam.Backup.Configuration.BackupProduct]::Create()
    $currentVersion = $ProductData.ProductVersion.ToString()
    if ($ProductData.MarketName -ne "") {$Version += " $($ProductData.MarketName)"}
    $version | Out-File -FilePath "C:\loggingdirectory\veeamversion.txt" -Append # (CHANGE ME)
    Write-Log "Veeam version successfully written to file."
    }
    catch {
    $ErrorMessage = "An error occurred while trying to get the Veeam version: $_"
    Write-Log $ErrorMessage
    # Add additional logging here if needed
    Add-Content -Path $LogFilePath -Value $ErrorMessage
}

Write-Log "Current Veeam Version is $currentVersion"

# Specify TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Specify The URL Of The File To Download
$url = "https://your.storage.com/VeeamBackupReplication_11.0.1.1261_20230227.exe" # (CHANGE ME)

# Specify a User Agent String To Use In The Request Headers
$userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:110.0.1) Gecko/20100101 Firefox/110.0.1"

# Specify The Location To Save The Downloaded File
$output = "C:\downloaddirectory\VeeamBackupReplication_11.0.1.1261_20230227.exe"

# Exclude Download Directory (CHANGE ME)
Set-MpPreference -ExclusionPath %SystemDrive%\downloaddirectory # (CHANGE ME)
Write-Log "C:\downloaddirectory Added to Defender Exclusion List" # (CHANGE ME)

# Disable Windows Defender
Set-MpPreference -DisableRealtimeMonitoring $true
Write-Log "Defender Disabled During Install"

# Variables for file size check and logging
$retryLimit = 20
$retryCount = 0

Write-Log "Begining Download of Patch From CDN"

# Download and verify the file size
do {
    $retryCount++

 # Resume or start downloading the file
  try {
      $webRequest = [System.Net.HttpWebRequest]::Create($url)
      $webRequest.UserAgent = $userAgent
      $webRequest.Method = "HEAD"
      $webRequest.Timeout = 15000
      $webResponse = $webRequest.GetResponse()
      $contentLength = $webResponse.ContentLength
      $webResponse.Close()

      if (Test-Path $output) {
          $localFileSize = (Get-Item $output).Length
          if ($localFileSize -lt $contentLength) {
              $startRange = $localFileSize
              $webClient = New-Object System.Net.WebClient
              $webClient.Headers["User-Agent"] = $userAgent
              $webClient.Headers["Range"] = "bytes=$startRange-"
              $webClient.DownloadFile($url, "$output.temp")
              $webClient.Dispose()
              Get-Content -Path "$output.temp" -ReadCount 0 | Add-Content -Path $output
              Remove-Item "$output.temp" -ErrorAction SilentlyContinue
          }
      } else {
          $webClient = New-Object System.Net.WebClient
          $webClient.Headers["User-Agent"] = $userAgent
          $webClient.DownloadFile($url, $output)
          $webClient.Dispose()
      }
  } catch {
      Write-Log "Error while downloading: $_. Retrying... ($retryCount of $retryLimit)"
      continue
  }

  # Check the file size
  $fileSize = (Get-Item $output).Length

  if ($fileSize -eq $contentLength) {
      Write-Log "File downloaded successfully."
      break
  } else {
      Write-Log "File size is incorrect. Retrying download... ($retryCount of $retryLimit)"
  }
  } while ($retryCount -lt $retryLimit)

  # If the file could not be downloaded correctly after retryLimit attempts
  if ($retryCount -eq $retryLimit) {
      Write-Log "Failed to download the correct file after $retryLimit attempts."
      exit
}

Write-Log "Disabling Veeam Backup Jobs"

# Disable veeam Backup Jobs
try {
    # Import the Veeam Backup PS Module
    Import-Module Veeam.Backup.PowerShell -Verbose

    # Get all backup jobs and filter enabled jobs
    $backupJobs = Get-VBRJob | Where-Object {$_.IsScheduleEnabled -eq $true}

    # Stop and Disable Enabled Backup Jobs
    foreach ($job in $backupJobs) {
        try {
            Stop-VBRJob -Job $job
            Disable-VBRJob -Job $job
        } catch {
            Write-Log "Error stopping and disabling job $($job.Name): $($_.Exception.Message)"
        }
    }

    $jobsStoppedAndDisabled = $false

    # Verify Veeam Jobs Stopped and Disabled Before Moving to Install
    do {
        $jobsStoppedAndDisabled = $true

        # Check if all jobs are stopped and disabled
        foreach ($job in $backupJobs) {
            $currentJob = Get-VBRJob | Where-Object { $_.Id -eq $job.Id }
            if ($currentJob.IsScheduleEnabled -eq $true) {
                $jobsStoppedAndDisabled = $false
                break
            }
        }

        if (-not $jobsStoppedAndDisabled) {
            Start-Sleep -Seconds 5
        }
    } while (-not $jobsStoppedAndDisabled)

    # Wait 60 Seconds
    Start-Sleep -Seconds 60

    Write-Log "Backup Jobs Stopped and Disabled: $backupJobs"
} catch {
    Write-Log "General Error: $($_.Exception.Message)"
}

Write-Log "Veeam Patch Starting Install"

# Install Patch
Start-Process "C:\downloaddirectory\VeeamBackupReplication_11.0.1.1261_20230227.exe" -ArgumentList '/silent /noreboot /log C:\loggingdirectory\veeam_patch_install.log VBR_AUTO_UPGRADE="1"' -Wait # (CHANGE ME)

Write-Log "Patch Process Has Run Run Check Log File @ C:\downloadditectory\veeam_patch_install.log For Errors" # (CHANGE ME)

#Get Veeam Version Write to Variable & Log
try {
    Write-Log "Getting Veeam version..."
    $InstallPath = Get-ItemProperty -Path "HKLM:\Software\Veeam\Veeam Backup and Replication" | Select-Object -ExpandProperty CorePath
    Add-Type -LiteralPath "$InstallPath\Veeam.Backup.Configuration.dll"
    $ProductData = [Veeam.Backup.Configuration.BackupProduct]::Create()
    $postInstallVersion = $ProductData.ProductVersion.ToString()
    if ($ProductData.MarketName -ne "") {$Version += " $($ProductData.MarketName)"}
    $version | Out-File -FilePath "C:\loggingdirectory\veeamversion.txt" -Append # (CHANGE ME)
    Write-Log "Veeam version successfully written to file."
    }
    catch {
    $ErrorMessage = "An error occurred while trying to get the Veeam version: $_"
    Write-Log $ErrorMessage
    # Add additional logging here if needed
    Add-Content -Path $LogFilePath -Value $ErrorMessage
}

Write-Log "Current Veeam Version is $postInstallVersion"

# Check if Install Was Successful
if ($postInstallVersion -gt $currentVersion) {
    Write-Log "Patch Install Was Successful. Veeam Is Now On Version $postInstallVersion."
} elseif ($postInstallVersion -eq $currentVersion){
    Write-Log "Patch Install Failed Check The Log File @ C:\loggingdirectory\veeam_patch_install.log" # (CHANGE ME)
}

Write-Log "Starting Veeam Jobs Back Up"

# Enable previously disabled backup jobs
foreach ($job in $backupJobs) {
    Enable-VBRJob -Job $job
}

# Enalbe Window Defender
Set-MpPreference -DisableRealtimeMonitoring $false
Write-Log "Defender Re-Enabled"

#End

