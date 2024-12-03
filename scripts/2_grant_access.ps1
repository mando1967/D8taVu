[CmdletBinding(SupportsShouldProcess=$true)]
param()

# Import configuration
$configPath = Join-Path $PSScriptRoot "config.ps1"
if (-not (Test-Path $configPath)) {
    Write-Host "Configuration file not found: $configPath" -ForegroundColor Red
    exit 1
}
. $configPath

# Get the application pool identity
$appPoolName = "D8TAVu"  # or your specific app pool name
$appPoolSid = "IIS AppPool\$appPoolName"

# Set the path to grant access to
$folderPath = "C:\Users\a-gon\OneDrive\Documents"

Write-ConfigLog "Granting access to $appPoolSid on $folderPath..."

# Get current ACL
$acl = Get-Acl $folderPath

# Create new rule for app pool
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $appPoolSid,
    "ReadAndExecute",
    "ContainerInherit,ObjectInherit",
    "None",
    "Allow"
)

# Check if permission already exists
$hasPermission = $false
foreach ($access in $acl.Access) {
    if ($access.IdentityReference.Value -eq $appPoolSid) {
        Write-ConfigLog "Permission already exists for $appPoolSid"
        $hasPermission = $true
        break
    }
}

if (-not $hasPermission) {
    if ($PSCmdlet.ShouldProcess($folderPath, "Grant access to $appPoolSid")) {
        # Add the rule to the ACL
        $acl.AddAccessRule($rule)

        # Apply the new ACL
        Set-Acl -Path $folderPath -AclObject $acl
        Write-ConfigLog "Permissions granted successfully"
    } else {
        Write-ConfigLog "[WhatIf] Would grant ReadAndExecute access to $appPoolSid" "Info"
        Write-ConfigLog "[WhatIf] Path: $folderPath" "Info"
        Write-ConfigLog "[WhatIf] Inheritance: ContainerInherit,ObjectInherit" "Info"
    }
}

Write-ConfigLog "Access grant operation completed"
