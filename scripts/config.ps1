# =============================================================================
# D8TAVu Configuration File
# =============================================================================
#
# Description:
# This file contains all configurable settings for the D8TAVu web application
# deployment and setup scripts. Modify these values according to your environment
# before running the setup scripts.
#
# Usage:
# This file is imported by master_setup.ps1 and master_setup_env.ps1
# Do not run this file directly.
#
# =============================================================================

# -----------------------------------------------------------------------------
# Application Settings
# -----------------------------------------------------------------------------
$APP_NAME = "D8TAVu"
$APP_POOL_NAME = "${APP_NAME}AppPool"
$APP_POOL_RUNTIME_VERSION = "v4.0"
$APP_POOL_PIPELINE_MODE = "Integrated"

# -----------------------------------------------------------------------------
# Web Application Settings
# -----------------------------------------------------------------------------
$WEB_SITE_NAME = "Default Web Site"
$VIRTUAL_PATH = "/$APP_NAME"
$VIRTUAL_DIR_NAME = "share"
$VIRTUAL_DIR_PATH = "$VIRTUAL_PATH/$VIRTUAL_DIR_NAME"

# -----------------------------------------------------------------------------
# Directory Paths
# -----------------------------------------------------------------------------
# Base paths
$APP_ROOT = "C:\inetpub\wwwroot\$APP_NAME"
$USER_FILES_PATH = "C:\Users\a-gon\OneDrive\Documents"
$SCRIPTS_DIR = $PSScriptRoot

# Application directories
$APP_BIN_DIR = Join-Path $APP_ROOT "bin"
$APP_STATIC_DIR = Join-Path $APP_ROOT "static"
$APP_TEMPLATES_DIR = Join-Path $APP_ROOT "templates"
$APP_LOGS_DIR = Join-Path $APP_ROOT "logs"

# -----------------------------------------------------------------------------
# Python Environment Settings
# -----------------------------------------------------------------------------
$PYTHON_VERSION = "3.9"
$ENV_NAME = "${APP_NAME}_web"
$CONDA_PATH = "C:\Users\a-gon\anaconda3"  # Modify this path for your environment
$ENV_YML_PATH = Join-Path (Split-Path $SCRIPTS_DIR -Parent) "environment.yml"

# -----------------------------------------------------------------------------
# IIS Settings
# -----------------------------------------------------------------------------
$IIS_HANDLER_NAME = "${APP_NAME}FastCGI"
$FASTCGI_PATH = Join-Path $APP_BIN_DIR "wfastcgi.py"
$URL_REWRITE_DOWNLOAD = "https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi"

# -----------------------------------------------------------------------------
# Security Settings
# -----------------------------------------------------------------------------
$IIS_USER = "IIS APPPOOL\$APP_POOL_NAME"
$REQUIRED_PERMISSIONS = @(
    "Read",
    "ReadAndExecute",
    "ListDirectory"
)
$ADMIN_PERMISSIONS = @(
    "FullControl"
)

# -----------------------------------------------------------------------------
# Logging Settings
# -----------------------------------------------------------------------------
$LOG_DIR = Join-Path $APP_ROOT "logs"
$SETUP_LOG = Join-Path $LOG_DIR "setup.log"
$ERROR_LOG = Join-Path $LOG_DIR "error.log"

# -----------------------------------------------------------------------------
# Script Execution Settings
# -----------------------------------------------------------------------------
$ABORT_ON_ERROR = $true
$VERIFY_ADMIN = $true
$RESTART_IIS_ON_COMPLETE = $true

# -----------------------------------------------------------------------------
# Configuration Validation
# -----------------------------------------------------------------------------
function Test-Configuration {
    $errors = @()

    # Validate required paths exist
    if (-not (Test-Path $CONDA_PATH)) {
        $errors += "Conda path not found: $CONDA_PATH"
    }
    
    if (-not (Test-Path $ENV_YML_PATH)) {
        $errors += "Environment.yml not found: $ENV_YML_PATH"
    }
    
    if (-not (Test-Path $USER_FILES_PATH)) {
        $errors += "User files path not found: $USER_FILES_PATH"
    }

    # Validate required values
    if ([string]::IsNullOrWhiteSpace($APP_NAME)) {
        $errors += "APP_NAME cannot be empty"
    }

    if ([string]::IsNullOrWhiteSpace($APP_POOL_NAME)) {
        $errors += "APP_POOL_NAME cannot be empty"
    }

    # Return validation results
    if ($errors.Count -gt 0) {
        Write-Host "Configuration validation failed:" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host "- $_" -ForegroundColor Red }
        return $false
    }
    
    Write-Host "Configuration validation passed" -ForegroundColor Green
    return $true
}

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------
function Write-ConfigLog {
    param(
        [string]$Message,
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Create log directory if it doesn't exist
    if (-not (Test-Path $LOG_DIR)) {
        New-Item -ItemType Directory -Path $LOG_DIR -Force | Out-Null
    }
    
    Add-Content -Path $SETUP_LOG -Value $logMessage
    
    switch ($Level) {
        "Error" { Write-Host $Message -ForegroundColor Red }
        "Warning" { Write-Host $Message -ForegroundColor Yellow }
        default { Write-Host $Message }
    }
}

# Export configuration
Export-ModuleMember -Variable * -Function *
