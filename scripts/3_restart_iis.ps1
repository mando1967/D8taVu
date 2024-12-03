[CmdletBinding(SupportsShouldProcess=$true)]
param()

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

# Function to execute commands with WhatIf support
function Invoke-WithWhatIf {
    param(
        [string]$Command,
        [string]$Description
    )
    
    if ($PSCmdlet.ShouldProcess($Description, $Command)) {
        Write-ConfigLog $Description
        Invoke-Expression $Command
    } else {
        Write-ConfigLog "[WhatIf] Would execute: $Command" "Info"
    }
}

# Restart IIS
Invoke-WithWhatIf -Command "iisreset /stop" -Description "Stopping IIS..."

# Stop Application Pool
Import-Module WebAdministration
Invoke-WithWhatIf -Command "Stop-WebAppPool -Name '$APP_NAME'" -Description "Stopping Application Pool..."

Write-ConfigLog "Waiting for 5 seconds..."
if (-not $PSCmdlet.ShouldProcess("Wait", "Wait for 5 seconds")) {
    Start-Sleep -Seconds 5
}

# Start Application Pool
Invoke-WithWhatIf -Command "Start-WebAppPool -Name '$APP_NAME'" -Description "Starting Application Pool..."

# Start IIS
Invoke-WithWhatIf -Command "iisreset /start" -Description "Starting IIS..."

Write-ConfigLog "IIS and Application Pool have been restarted successfully"

Write-ConfigLog "Done! Please try accessing your application now."
