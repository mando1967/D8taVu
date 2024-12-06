[CmdletBinding(SupportsShouldProcess=$true)]
param()

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
# Requirements:
# - Windows OS with PowerShell
# - Administrator privileges
# - All component scripts must be present in the same directory
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

Write-ConfigLog "Starting IIS setup for $APP_NAME"

# Function to execute scripts with WhatIf support
function Invoke-SetupScript {
    param(
        [string]$Path,
        [string]$Description
    )

    if (-not (Test-Path $Path)) {
        $errorMessage = "Script not found: $Path"
        Write-Host $errorMessage -ForegroundColor Red
        Write-ConfigLog $errorMessage "Error"
        if ($ABORT_ON_ERROR) { exit 1 }
        return $false
    }

    $extension = [System.IO.Path]::GetExtension($Path)
    $errorOccurred = $false

    try {
        switch ($extension) {
            ".ps1" {
                if ($PSCmdlet.ShouldProcess($Path, $Description)) {
                    & $Path
                    if ($LASTEXITCODE -ne 0) { $errorOccurred = $true }
                } else {
                    Write-ConfigLog "[WhatIf] Would execute PowerShell script: $Path" "Info"
                    Write-ConfigLog "[WhatIf] Description: $Description" "Info"
                }
            }
            ".bat" {
                if ($PSCmdlet.ShouldProcess($Path, $Description)) {
                    $whatIfArg = "0"  # Not in WhatIf mode
                } else {
                    $whatIfArg = "1"  # WhatIf mode
                }
                $process = Start-Process -FilePath $Path -ArgumentList "$whatIfArg", "`"$Description`"" -Wait -PassThru -NoNewWindow
                if ($process.ExitCode -ne 0) { $errorOccurred = $true }
            }
            default {
                $errorMessage = "Unsupported script type: $extension"
                Write-Host $errorMessage -ForegroundColor Red
                Write-ConfigLog $errorMessage "Error"
                if ($ABORT_ON_ERROR) { exit 1 }
                return $false
            }
        }

        if ($errorOccurred) {
            $errorMessage = "Script failed: $Path"
            Write-Host $errorMessage -ForegroundColor Red
            Write-ConfigLog $errorMessage "Error"
            if ($ABORT_ON_ERROR) { exit 1 }
            return $false
        }
        else {
            Write-Host "Success: $Description" -ForegroundColor Green
            Write-ConfigLog "Success: $Description"
            return $true
        }
    }
    catch {
        $errorMessage = "Error executing $Path`: $($_.Exception.Message)"
        Write-Host $errorMessage -ForegroundColor Red
        Write-ConfigLog $errorMessage "Error"
        if ($ABORT_ON_ERROR) { exit 1 }
        return $false
    }
}

# Define script sequence
$scripts = @(
    @{
        Path = Join-Path $SCRIPTS_DIR "1_install_iis_components.bat"
        Description = "Installing IIS Components"
    },
    @{
        Path = Join-Path $SCRIPTS_DIR "1_unlock_iis_sections.bat"
        Description = "Unlocking IIS Sections"
    },
    @{
        Path = Join-Path $SCRIPTS_DIR "1_install_url_rewrite.ps1"
        Description = "Installing URL Rewrite Module"
    },
    @{
        Path = Join-Path $SCRIPTS_DIR "1_create_app_pool.ps1"
        Description = "Creating Application Pool"
    },
    @{
        Path = Join-Path $SCRIPTS_DIR "1_enable_wfastcgi.bat"
        Description = "Enabling FastCGI"
    },
    @{
        Path = Join-Path $SCRIPTS_DIR "1_set_env_variables.ps1"
        Description = "Setting Environment Variables"
    },
    @{
        Path = Join-Path $SCRIPTS_DIR "1_configure_virtual_directory.ps1"
        Description = "Configuring Virtual Directory"
    },
    @{
        Path = Join-Path $SCRIPTS_DIR "1_check_set_permissions.ps1"
        Description = "Setting Permissions"
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

if (-not $WhatIfPreference) {
    Write-Host "`nPress any key to continue or Ctrl+C to abort..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

foreach ($script in $scripts) {
    Write-Host "`nExecuting: $($script.Description)" -ForegroundColor Cyan
    Write-ConfigLog "Executing: $($script.Description)"
    
    Invoke-SetupScript -Path $script.Path -Description $script.Description
}

Write-Host "`nSetup completed successfully!" -ForegroundColor Green
Write-ConfigLog "Setup completed successfully"
