[CmdletBinding(SupportsShouldProcess=$true)]
param()

# Import configuration
$configPath = Join-Path $PSScriptRoot "config.ps1"
if (-not (Test-Path $configPath)) {
    Write-Host "Configuration file not found: $configPath" -ForegroundColor Red
    exit 1
}
. $configPath

# Import WebAdministration module
Import-Module WebAdministration

Write-ConfigLog "Configuring virtual directory for $APP_NAME..."

# Configuration
$siteName = $WEB_SITE_NAME
$appName = $APP_NAME
$virtualDirName = $VIRTUAL_DIR_NAME
$physicalPath = $USER_FILES_PATH
$appPoolName = $APP_NAME
$appPoolIdentity = "IIS AppPool\$appPoolName"

Write-ConfigLog "Configuring virtual directory for D8TAVu..."

# Check if virtual directory exists
$virtualDirPath = "IIS:\Sites\$siteName\$appName\$virtualDirName"
if (Test-Path $virtualDirPath) {
    Write-ConfigLog "Virtual directory already exists. Removing..."
    if ($PSCmdlet.ShouldProcess($virtualDirPath, "Remove Virtual Directory")) {
        Remove-Item $virtualDirPath -Recurse -Force
    } else {
        Write-ConfigLog "[WhatIf] Would remove virtual directory: $virtualDirPath" "Info"
    }
}

# Create virtual directory
Write-ConfigLog "Creating virtual directory..."
if ($PSCmdlet.ShouldProcess("$siteName/$appName/$virtualDirName", "Create Virtual Directory")) {
    New-WebVirtualDirectory -Site $siteName -Application $appName -Name $virtualDirName -PhysicalPath $physicalPath
} else {
    Write-ConfigLog "[WhatIf] Would create virtual directory: $virtualDirName" "Info"
    Write-ConfigLog "[WhatIf] Site: $siteName" "Info"
    Write-ConfigLog "[WhatIf] Application: $appName" "Info"
    Write-ConfigLog "[WhatIf] Physical Path: $physicalPath" "Info"
}

# Set directory permissions
Write-ConfigLog "Setting directory permissions..."
$acl = Get-Acl $physicalPath

# Create access rule for required permissions
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $IIS_USER,
    $REQUIRED_PERMISSIONS,
    "ContainerInherit,ObjectInherit",
    "None",
    "Allow"
)

# Check if permission already exists
$hasPermission = $false
foreach ($access in $acl.Access) {
    if ($access.IdentityReference.Value -eq $IIS_USER) {
        Write-ConfigLog "Permission already exists for $IIS_USER"
        $hasPermission = $true
        break
    }
}

if (-not $hasPermission) {
    if ($PSCmdlet.ShouldProcess($physicalPath, "Set ACL permissions for $IIS_USER")) {
        $acl.AddAccessRule($accessRule)
        try {
            Set-Acl -Path $physicalPath -AclObject $acl
            Write-ConfigLog "Added permissions for $IIS_USER"
        }
        catch {
            $errorMessage = "Error setting permissions: $($_.Exception.Message)"
            Write-ConfigLog $errorMessage "Error"
            if ($ABORT_ON_ERROR) { exit 1 }
        }
    } else {
        Write-ConfigLog "[WhatIf] Would add permissions for $IIS_USER" "Info"
        Write-ConfigLog "[WhatIf] Path: $physicalPath" "Info"
        Write-ConfigLog "[WhatIf] Permissions: $REQUIRED_PERMISSIONS" "Info"
    }
}

Write-ConfigLog "Virtual directory configuration completed"
Write-ConfigLog "Virtual Directory URL: http://localhost/$appName/$virtualDirName"
