# Restart IIS
Write-Host "Stopping IIS..."
Stop-Service -Name W3SVC -Force
Start-Sleep -Seconds 2
Write-Host "Starting IIS..."
Start-Service -Name W3SVC
Write-Host "IIS has been restarted."

# Optionally, you can also restart the application pool
$appPoolName = "D8TAVu"
Write-Host "Restarting application pool $appPoolName..."
Import-Module WebAdministration
Restart-WebAppPool -Name $appPoolName
Write-Host "Application pool has been restarted."

Write-Host "Done! Please try accessing your application now."
