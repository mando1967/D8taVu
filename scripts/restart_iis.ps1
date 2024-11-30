# Get the root directory (one level up from scripts)
$rootDir = Split-Path -Parent $PSScriptRoot

# Restart IIS
Write-Host "Stopping IIS..."
iisreset /stop

Write-Host "Stopping Application Pool..."
Import-Module WebAdministration
Stop-WebAppPool -Name "D8TAVu"

Write-Host "Waiting for 5 seconds..."
Start-Sleep -Seconds 5

Write-Host "Starting Application Pool..."
Start-WebAppPool -Name "D8TAVu"

Write-Host "Starting IIS..."
iisreset /start

Write-Host "IIS and Application Pool have been restarted."

Write-Host "Done! Please try accessing your application now."
