# Import configuration
$configPath = Join-Path $PSScriptRoot "config.ps1"
if (-not (Test-Path $configPath)) {
    Write-Host "Configuration file not found: $configPath" -ForegroundColor Red
    exit 1
}
. $configPath

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
        New-Item -Path $path -ItemType Directory -Force
        Write-ConfigLog "Created share directory: $path"
    }
    # Create file if it's app.log and doesn't exist
    elseif ($path -eq (Join-Path $APP_ROOT "app.log") -and !(Test-Path $path)) {
        New-Item -Path $path -ItemType File -Force
        Write-ConfigLog "Created log file: $path"
    }

    # Get current ACL
    $acl = Get-Acl $path
    
    # Check if identity already has permissions
    $hasPermission = $false
    foreach ($access in $acl.Access) {
        if ($access.IdentityReference.Value -eq $IIS_USER) {
            Write-ConfigLog "Current permissions for $IIS_USER:"
            Write-ConfigLog "- FileSystemRights: $($access.FileSystemRights)"
            Write-ConfigLog "- AccessControlType: $($access.AccessControlType)"
            $hasPermission = $true
        }
    }

    if (-not $hasPermission) {
        Write-ConfigLog "$IIS_USER has no explicit permissions"
        
        # Add permissions
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $IIS_USER,
            $REQUIRED_PERMISSIONS,
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )
        $acl.AddAccessRule($accessRule)
        
        try {
            Set-Acl -Path $path -AclObject $acl
            Write-ConfigLog "Added $REQUIRED_PERMISSIONS permissions for $IIS_USER"
        }
        catch {
            $errorMessage = "Error setting permissions: $_"
            Write-ConfigLog $errorMessage "Error"
            if ($ABORT_ON_ERROR) { exit 1 }
        }
    }
}

Write-ConfigLog "Permission check and setup completed"
