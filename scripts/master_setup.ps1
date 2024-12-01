# =============================================================================
# D8TAVu IIS Master Setup Script
# =============================================================================
#
# Description:
# This master script automates the complete IIS setup process for D8TAVu web application.
# It runs a sequence of PowerShell and batch scripts in the correct order, with error
# checking at each step. If any script fails, the entire process is aborted and the
# error is reported.
#
# Features:
# - Administrator privilege verification
# - Error handling for both PowerShell and batch scripts
# - Progress tracking and color-coded status output
# - Automatic abort on any script failure
# - Support for both .ps1 and .bat files
#
# Script Sequence:
# 1. 1_install_iis_components.bat     - Installs required IIS components
# 2. 1_unlock_iis_sections.bat       - Unlocks IIS configuration sections
# 3. 1_install_url_rewrite.ps1       - Installs and configures URL Rewrite Module
# 4. 1_create_app_pool.ps1           - Creates application pool and web application
# 5. 1_enable_wfastcgi.bat           - Enables FastCGI
# 6. 1_set_env_variables.ps1         - Sets required environment variables
# 7. 1_configure_virtual_directory.ps1 - Configures virtual directory
# 8. 1_check_set_permissions.ps1     - Sets necessary file permissions
# 9. 3_restart_iis.ps1              - Restarts IIS to apply changes
#
# Usage:
# 1. Open PowerShell as Administrator
# 2. Navigate to the D8TAVu scripts directory
# 3. Run: .\master_setup.ps1
#
# Requirements:
# - Windows OS with PowerShell
# - Administrator privileges
# - All component scripts must be present in the same directory
#
# Error Handling:
# - If any script fails, the process will:
#   a) Display detailed error information
#   b) Stop the entire process
#   c) Report which step failed
#   d) Preserve error state for troubleshooting
#
# =============================================================================

# Check for administrator privileges
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "This script requires administrator privileges. Please run as administrator." -ForegroundColor Red
    exit 1
}

# Function to run a script and check for errors
function Invoke-ScriptWithErrorCheck {
    param(
        [string]$ScriptPath,
        [string]$Description
    )
    
    Write-Host "`n=== Running: $Description ===" -ForegroundColor Cyan
    
    # Get file extension
    $extension = [System.IO.Path]::GetExtension($ScriptPath)
    
    try {
        if ($extension -eq ".bat") {
            # For batch files, run using cmd.exe
            $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$ScriptPath`"" -Wait -PassThru -NoNewWindow
            if ($process.ExitCode -ne 0) {
                throw "Batch file execution failed with exit code: $($process.ExitCode)"
            }
        }
        else {
            # For PowerShell scripts, dot source them to run in current scope
            . $ScriptPath
            if ($LASTEXITCODE -ne 0) {
                throw "PowerShell script execution failed with exit code: $LASTEXITCODE"
            }
        }
        Write-Host "Successfully completed: $Description" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Error during: $Description" -ForegroundColor Red
        Write-Host "Error details: $_" -ForegroundColor Red
        return $false
    }
}

# Store the script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Define the sequence of scripts to run
$scripts = @(
    @{
        Path = Join-Path $scriptDir "1_install_iis_components.bat"
        Description = "Installing IIS Components"
    },
    @{
        Path = Join-Path $scriptDir "1_unlock_iis_sections.bat"
        Description = "Unlocking IIS Configuration Sections"
    },
    @{
        Path = Join-Path $scriptDir "1_install_url_rewrite.ps1"
        Description = "Installing and Configuring URL Rewrite Module"
    },
    @{
        Path = Join-Path $scriptDir "1_create_app_pool.ps1"
        Description = "Creating Application Pool and Web Application"
    },
    @{
        Path = Join-Path $scriptDir "1_enable_wfastcgi.bat"
        Description = "Enabling FastCGI"
    },
    @{
        Path = Join-Path $scriptDir "1_set_env_variables.ps1"
        Description = "Setting Environment Variables"
    },
    @{
        Path = Join-Path $scriptDir "1_configure_virtual_directory.ps1"
        Description = "Configuring Virtual Directory"
    },
    @{
        Path = Join-Path $scriptDir "1_check_set_permissions.ps1"
        Description = "Setting File Permissions"
    },
    @{
        Path = Join-Path $scriptDir "3_restart_iis.ps1"
        Description = "Restarting IIS to Apply Changes"
    }
)

# Run each script in sequence
Write-Host "Starting D8TAVu IIS Setup..." -ForegroundColor Yellow
Write-Host "This script will run the following steps:"
$scripts | ForEach-Object { Write-Host "- $($_.Description)" }
Write-Host "`nPress any key to continue or Ctrl+C to abort..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

foreach ($script in $scripts) {
    # Check if script file exists
    if (-not (Test-Path $script.Path)) {
        Write-Host "Error: Script not found: $($script.Path)" -ForegroundColor Red
        exit 1
    }
    
    # Run the script and check for success
    $success = Invoke-ScriptWithErrorCheck -ScriptPath $script.Path -Description $script.Description
    
    # If any script fails, abort the entire process
    if (-not $success) {
        Write-Host "`nSetup aborted due to error in: $($script.Description)" -ForegroundColor Red
        Write-Host "Please fix the error and run the setup again." -ForegroundColor Red
        exit 1
    }
}

Write-Host "`nD8TAVu IIS Setup completed successfully!" -ForegroundColor Green
Write-Host "You may need to restart IIS or your computer for all changes to take effect."
Write-Host "To restart IIS, you can run: scripts\restart_iis.ps1"
