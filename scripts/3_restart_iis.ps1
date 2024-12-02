# Get the root directory (one level up from scripts)
$rootDir = Split-Path -Parent $PSScriptRoot

# Import configuration
$configPath = Join-Path $PSScriptRoot "config.ps1"
if (-not (Test-Path $configPath)) {
    Write-Host "Configuration file not found: $configPath" -ForegroundColor Red
    exit 1
}
. $configPath

Write-ConfigLog "Restarting IIS and Application Pool..."

# Restart IIS
Write-ConfigLog "Stopping IIS..."
iisreset /stop

Write-ConfigLog "Stopping Application Pool..."
Import-Module WebAdministration
Stop-WebAppPool -Name $APP_NAME

Write-ConfigLog "Waiting for 5 seconds..."
Start-Sleep -Seconds 5

Write-ConfigLog "Starting Application Pool..."
Start-WebAppPool -Name $APP_NAME

Write-ConfigLog "Starting IIS..."
iisreset /start

Write-ConfigLog "IIS and Application Pool have been restarted successfully"

Write-ConfigLog "Done! Please try accessing your application now."
