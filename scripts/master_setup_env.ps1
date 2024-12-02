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
# Requirements:
# - Windows OS with PowerShell
# - Administrator privileges
# - All component scripts must be present in the same directory
# - IIS setup must be completed first (run master_setup.ps1)
# - Anaconda/Miniconda must be installed
#
# =============================================================================

# Import configuration
$configPath = Join-Path $PSScriptRoot "config.ps1"
if (-not (Test-Path $configPath)) {
    Write-Host "Configuration file not found: $configPath" -ForegroundColor Red
    exit 1
}
. $configPath

# Validate configuration
if (-not (Test-Configuration)) {
    Write-Host "Configuration validation failed. Please check config.ps1" -ForegroundColor Red
    exit 1
}

# Check for administrator privileges if required
if ($VERIFY_ADMIN) {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Host "This script must be run as Administrator" -ForegroundColor Red
        exit 1
    }
}

Write-ConfigLog "Starting environment setup for $APP_NAME"

# Define script sequence
$scripts = @(
    @{
        Path = Join-Path $SCRIPTS_DIR "2_create_web_env.ps1"
        Description = "Creating Python Environment"
    },
    @{
        Path = Join-Path $SCRIPTS_DIR "2_copy_static_files.ps1"
        Description = "Copying Static Files"
    },
    @{
        Path = Join-Path $SCRIPTS_DIR "2_set_permissions.ps1"
        Description = "Setting Permissions"
    },
    @{
        Path = Join-Path $SCRIPTS_DIR "2_fix_permissions.ps1"
        Description = "Fixing Permissions"
    },
    @{
        Path = Join-Path $SCRIPTS_DIR "2_grant_access.ps1"
        Description = "Granting Access"
    }
)

if ($RESTART_IIS_ON_COMPLETE) {
    $scripts += @{
        Path = Join-Path $SCRIPTS_DIR "3_restart_iis.ps1"
        Description = "Restarting IIS"
    }
}

Write-Host "`nScript sequence:" -ForegroundColor Cyan
$scripts | ForEach-Object { Write-Host "- $($_.Description)" }

Write-Host "`nPress any key to continue or Ctrl+C to abort..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

foreach ($script in $scripts) {
    Write-Host "`nExecuting: $($script.Description)" -ForegroundColor Cyan
    Write-ConfigLog "Executing: $($script.Description)"

    # Check if script file exists
    if (-not (Test-Path $script.Path)) {
        $errorMessage = "Script not found: $($script.Path)"
        Write-Host $errorMessage -ForegroundColor Red
        Write-ConfigLog $errorMessage "Error"
        if ($ABORT_ON_ERROR) { exit 1 }
        continue
    }

    # Execute script based on file extension
    $extension = [System.IO.Path]::GetExtension($script.Path)
    $errorOccurred = $false

    try {
        switch ($extension) {
            ".ps1" {
                & $script.Path
                if ($LASTEXITCODE -ne 0) { $errorOccurred = $true }
            }
            ".bat" {
                $process = Start-Process -FilePath $script.Path -Wait -PassThru -NoNewWindow
                if ($process.ExitCode -ne 0) { $errorOccurred = $true }
            }
            default {
                $errorMessage = "Unsupported script type: $extension"
                Write-Host $errorMessage -ForegroundColor Red
                Write-ConfigLog $errorMessage "Error"
                if ($ABORT_ON_ERROR) { exit 1 }
                continue
            }
        }

        if ($errorOccurred) {
            $errorMessage = "Script failed: $($script.Path)"
            Write-Host $errorMessage -ForegroundColor Red
            Write-ConfigLog $errorMessage "Error"
            if ($ABORT_ON_ERROR) { exit 1 }
        }
        else {
            Write-Host "Success: $($script.Description)" -ForegroundColor Green
            Write-ConfigLog "Success: $($script.Description)"
        }
    }
    catch {
        $errorMessage = "Error executing $($script.Path): $_"
        Write-Host $errorMessage -ForegroundColor Red
        Write-ConfigLog $errorMessage "Error"
        if ($ABORT_ON_ERROR) { exit 1 }
    }
}

Write-Host "`nEnvironment setup completed successfully!" -ForegroundColor Green
Write-ConfigLog "Environment setup completed successfully"
