# =============================================================================
# D8TAVu Environment Setup Master Script
# =============================================================================
#
# Description:
# This master script automates the environment setup process for D8TAVu web application.
# It handles the creation of the Python environment, copying of application files,
# and setting up all necessary permissions. This script should be run after the
# IIS setup is complete (master_setup.ps1).
#
# Features:
# - Administrator privilege verification
# - Error handling for both PowerShell and batch scripts
# - Progress tracking and color-coded status output
# - Automatic abort on any script failure
# - Support for both .ps1 and .bat files
#
# Script Sequence:
# 1. 2_create_web_env.ps1           - Creates Python environment and sets initial permissions
# 2. 2_copy_static_files.ps1        - Copies application files to web directory
# 3. 2_set_permissions.ps1          - Sets comprehensive file permissions
# 4. 2_fix_permissions.ps1          - Fixes any remaining permission issues
# 5. 2_grant_access.ps1            - Grants necessary access rights
# 6. 3_restart_iis.ps1             - Restarts IIS to apply changes
#
# Usage:
# 1. Open PowerShell as Administrator
# 2. Navigate to the D8TAVu scripts directory
# 3. Run: .\master_setup_env.ps1
#
# Requirements:
# - Windows OS with PowerShell
# - Administrator privileges
# - All component scripts must be present in the same directory
# - IIS setup must be completed first (run master_setup.ps1)
# - Anaconda/Miniconda must be installed
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
        Path = Join-Path $scriptDir "2_create_web_env.ps1"
        Description = "Creating Python Environment and Setting Initial Permissions"
    },
    @{
        Path = Join-Path $scriptDir "2_copy_static_files.ps1"
        Description = "Copying Application Files to Web Directory"
    },
    @{
        Path = Join-Path $scriptDir "2_set_permissions.ps1"
        Description = "Setting Comprehensive File Permissions"
    },
    @{
        Path = Join-Path $scriptDir "2_fix_permissions.ps1"
        Description = "Fixing Any Remaining Permission Issues"
    },
    @{
        Path = Join-Path $scriptDir "2_grant_access.ps1"
        Description = "Granting Necessary Access Rights"
    },
    @{
        Path = Join-Path $scriptDir "3_restart_iis.ps1"
        Description = "Restarting IIS to Apply Changes"
    }
)

# Run each script in sequence
Write-Host "Starting D8TAVu Environment Setup..." -ForegroundColor Yellow
Write-Host "This script will run the following steps:"
$scripts | ForEach-Object { Write-Host "- $($_.Description)" }
Write-Host "`nImportant: Make sure IIS setup (master_setup.ps1) has been completed first."
Write-Host "Press any key to continue or Ctrl+C to abort..."
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

Write-Host "`nD8TAVu Environment Setup completed successfully!" -ForegroundColor Green
Write-Host "The Python environment and application files have been set up."
Write-Host "You can now proceed with running the application."
