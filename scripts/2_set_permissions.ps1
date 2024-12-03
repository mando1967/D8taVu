[CmdletBinding(SupportsShouldProcess=$true)]
param()

# Import configuration
$configPath = Join-Path $PSScriptRoot "config.ps1"
if (-not (Test-Path $configPath)) {
    Write-Host "Configuration file not found: $configPath" -ForegroundColor Red
    exit 1
}
. $configPath

# Get the root directory (one level up from scripts)
$rootDir = Split-Path -Parent $PSScriptRoot

# Define paths and users
$webAppPath = "$rootDir\web"
$envPath = "$webAppPath\env"
$user = "IIS APPPOOL\D8TAVu"

# Function to remove read-only attributes recursively
function Remove-ReadOnlyAttribute {
    param (
        [string]$path
    )
    
    try {
        if (Test-Path $path) {
            if ($PSCmdlet.ShouldProcess($path, "Remove read-only attributes")) {
                # Remove read-only from the item itself
                $item = Get-Item $path -Force
                if ($item.Attributes -band [System.IO.FileAttributes]::ReadOnly) {
                    $item.Attributes = $item.Attributes -bxor [System.IO.FileAttributes]::ReadOnly
                }
                
                # If it's a directory, process contents
                if ($item.PSIsContainer) {
                    Get-ChildItem $path -Recurse -Force | ForEach-Object {
                        if ($_.Attributes -band [System.IO.FileAttributes]::ReadOnly) {
                            $_.Attributes = $_.Attributes -bxor [System.IO.FileAttributes]::ReadOnly
                        }
                    }
                }
                Write-ConfigLog "Removed read-only attributes from $path"
            } else {
                Write-ConfigLog "[WhatIf] Would remove read-only attributes from $path" "Info"
            }
        }
    }
    catch {
        Write-ConfigLog "Warning: Could not remove read-only attribute from $path : $($_.Exception.Message)" "Warning"
    }
}

# Function to set permissions using icacls
function Set-IcaclsPermissions {
    param (
        [string]$path,
        [string]$user
    )
    
    try {
        Write-ConfigLog "Setting permissions for $path using icacls..."
        if ($PSCmdlet.ShouldProcess($path, "Set ICACLS permissions for $user")) {
            $result = Start-Process "icacls.exe" -ArgumentList "`"$path`" /grant `"$user`":(OI)(CI)F /T /Q" -NoNewWindow -Wait -PassThru
            if ($result.ExitCode -eq 0) {
                Write-ConfigLog "Successfully set permissions for $path" "Success"
                return $true
            } else {
                Write-ConfigLog "Failed to set permissions for $path. Exit code: $($result.ExitCode)" "Error"
                return $false
            }
        } else {
            Write-ConfigLog "[WhatIf] Would set permissions using icacls" "Info"
            Write-ConfigLog "[WhatIf] Path: $path" "Info"
            Write-ConfigLog "[WhatIf] User: $user" "Info"
            Write-ConfigLog "[WhatIf] Permissions: Full Control (OI)(CI)F" "Info"
            return $true
        }
    }
    catch {
        Write-ConfigLog "Error setting permissions for $path : $($_.Exception.Message)" "Error"
        return $false
    }
}

# Main directories to set permissions on
$mainDirs = @(
    $envPath,
    "$envPath\Lib",
    "$envPath\Lib\site-packages",
    "$envPath\Scripts",
    $webAppPath
)

# Process each directory
$success = $true
foreach ($dir in $mainDirs) {
    if (Test-Path $dir) {
        Write-ConfigLog "Processing directory: $dir"
        
        # Remove read-only attributes
        Remove-ReadOnlyAttribute -path $dir
        
        # Set permissions
        if (-not (Set-IcaclsPermissions -path $dir -user $user)) {
            $success = $false
        }
    }
    else {
        Write-ConfigLog "Directory not found: $dir" "Error"
        $success = $false
    }
}

if ($success) {
    Write-ConfigLog "All permissions have been set successfully!" "Success"
}
else {
    Write-ConfigLog "There were some issues setting permissions. Please check the messages above." "Warning"
}
