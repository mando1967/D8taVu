# Paths to check/set permissions
$paths = @(
    "C:\inetpub\wwwroot\D8TAVu",
    "C:\inetpub\wwwroot\D8TAVu\app.log",
    "C:\inetpub\wwwroot\D8TAVu\share"
)

# Application Pool Identity
$appPoolName = "D8TAVu"
$appPoolIdentity = "IIS AppPool\${appPoolName}"

Write-Host "Checking permissions for ${appPoolIdentity}..."
Write-Host ""

foreach ($path in $paths) {
    Write-Host "Checking ${path}..."
    
    # Create directory if it's share and doesn't exist
    if ($path -eq "C:\inetpub\wwwroot\D8TAVu\share" -and !(Test-Path $path)) {
        New-Item -Path $path -ItemType Directory -Force
        Write-Host "Created share directory: ${path}"
    }
    # Create file if it's app.log and doesn't exist
    elseif ($path -eq "C:\inetpub\wwwroot\D8TAVu\app.log" -and !(Test-Path $path)) {
        New-Item -Path $path -ItemType File -Force
        Write-Host "Created log file: ${path}"
    }

    # Get current ACL
    $acl = Get-Acl $path
    
    # Check if identity already has permissions
    $hasPermission = $false
    foreach ($access in $acl.Access) {
        if ($access.IdentityReference.Value -eq $appPoolIdentity) {
            Write-Host "Current permissions for ${appPoolIdentity}:"
            Write-Host "- FileSystemRights: $($access.FileSystemRights)"
            Write-Host "- AccessControlType: $($access.AccessControlType)"
            $hasPermission = $true
        }
    }

    if (-not $hasPermission) {
        Write-Host "${appPoolIdentity} has no explicit permissions"
        
        # Add permissions
        $permission = $appPoolIdentity, "Modify", "ContainerInherit,ObjectInherit", "None", "Allow"
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
        $acl.AddAccessRule($accessRule)
        
        try {
            Set-Acl -Path $path -AclObject $acl
            Write-Host "Added Modify permissions for ${appPoolIdentity}"
        }
        catch {
            Write-Host "Error setting permissions: $_"
        }
    }
    
    Write-Host ""
}

Write-Host "Permission check/set complete"
