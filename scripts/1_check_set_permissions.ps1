[CmdletBinding(SupportsShouldProcess=$true)]
param()

# Import configuration
$configPath = Join-Path $PSScriptRoot "config.ps1"
if (-not (Test-Path $configPath)) {
    Write-Host "Configuration file not found: $configPath" -ForegroundColor Red
    exit 1
}
. $configPath

function Invoke-WithWhatIf {
    param(
        [string]$Command,
        [string]$Description,
        [string]$Target = ""
    )
    
    if ($PSCmdlet.ShouldProcess($Target, $Description)) {
        Write-ConfigLog $Description
        Invoke-Expression $Command
    } else {
        Write-ConfigLog "[WhatIf] Would execute: $Command" "Info"
        Write-ConfigLog $Description
    }
}

function Test-AppPoolIdentity {
    param(
        [string]$Identity
    )
    
    try {
        # Try to translate the identity
        $ntAccount = New-Object System.Security.Principal.NTAccount($Identity)
        $sid = $ntAccount.Translate([System.Security.Principal.SecurityIdentifier])
        return $true
    }
    catch {
        return $false
    }
}

# Verify app pool identity exists
if (-not (Test-AppPoolIdentity $IIS_USER)) {
    $errorMessage = "IIS app pool identity '$IIS_USER' does not exist. Please ensure the app pool is created first."
    Write-ConfigLog $errorMessage "Error"
    if ($ABORT_ON_ERROR) {
        throw $errorMessage
    }
    exit 1
}

# Paths to check/set permissions
$paths = @(
    $APP_ROOT,
    (Join-Path $APP_ROOT "app.log"),
    (Join-Path $APP_ROOT $VIRTUAL_DIR_NAME)
)

Write-ConfigLog "Checking permissions for $IIS_USER..."

foreach ($path in $paths) {
    Write-ConfigLog "Checking $path..."
    
    # Create directory if it's share and doesn't exist
    if ($path -eq (Join-Path $APP_ROOT $VIRTUAL_DIR_NAME) -and !(Test-Path $path)) {
        Invoke-WithWhatIf -Command "New-Item -Path '$path' -ItemType Directory -Force" `
                         -Description "Creating share directory: $path" `
                         -Target $path
        Write-ConfigLog "Created share directory: $path"
    }
    # Create file if it's app.log and doesn't exist
    elseif ($path -eq (Join-Path $APP_ROOT "app.log") -and !(Test-Path $path)) {
        Invoke-WithWhatIf -Command "New-Item -Path '$path' -ItemType File -Force" `
                         -Description "Creating log file: $path" `
                         -Target $path
        Write-ConfigLog "Created log file: $path"
    }

    # Get current ACL
    $acl = Get-Acl $path
    
    # Check if identity already has permissions
    $hasPermission = $false
    foreach ($access in $acl.Access) {
        if ($access.IdentityReference.Value -eq $IIS_USER) {
            Write-ConfigLog "Current permissions for $IIS_USER"
            Write-ConfigLog "- FileSystemRights: $($access.FileSystemRights)"
            Write-ConfigLog "- AccessControlType: $($access.AccessControlType)"
            $hasPermission = $true
        }
    }

    if (-not $hasPermission) {
        Write-ConfigLog "Adding permissions for $IIS_USER..."
        
        try {
            # Create new rule
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                $IIS_USER,
                $REQUIRED_PERMISSIONS,
                "ContainerInherit,ObjectInherit",
                "None",
                "Allow"
            )
            
            # Add rule to ACL
            $acl.AddAccessRule($rule)
            
            # Apply new ACL
            Invoke-WithWhatIf -Command "Set-Acl -Path '$path' -AclObject `$acl" `
                             -Description "Setting permissions for $IIS_USER on $path" `
                             -Target $path
            Write-ConfigLog "Successfully added permissions for $IIS_USER"
        }
        catch {
            $errorMessage = "Failed to set permissions: $_"
            Write-ConfigLog $errorMessage "Error"
            if ($ABORT_ON_ERROR) {
                throw $errorMessage
            }
        }
    }
    else {
        Write-ConfigLog "Required permissions already exist for $IIS_USER"
    }
}

Write-ConfigLog "Permission check/set completed"
