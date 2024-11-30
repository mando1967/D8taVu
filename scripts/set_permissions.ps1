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
        }
    }
    catch {
        Write-Host "Warning: Could not remove read-only attribute from $path : $_" -ForegroundColor Yellow
    }
}

# Function to set permissions using icacls
function Set-IcaclsPermissions {
    param (
        [string]$path,
        [string]$user
    )
    
    try {
        Write-Host "`nSetting permissions for $path using icacls..."
        $result = Start-Process "icacls.exe" -ArgumentList "`"$path`" /grant `"$user`":(OI)(CI)F /T /Q" -NoNewWindow -Wait -PassThru
        if ($result.ExitCode -eq 0) {
            Write-Host "Successfully set permissions for $path" -ForegroundColor Green
            return $true
        } else {
            Write-Host "Failed to set permissions for $path. Exit code: $($result.ExitCode)" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "Error setting permissions for $path : $_" -ForegroundColor Red
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
        Write-Host "`nProcessing directory: $dir"
        
        # Remove read-only attributes
        Remove-ReadOnlyAttribute -path $dir
        
        # Set permissions
        if (-not (Set-IcaclsPermissions -path $dir -user $user)) {
            $success = $false
        }
    }
    else {
        Write-Host "Directory not found: $dir" -ForegroundColor Red
        $success = $false
    }
}

if ($success) {
    Write-Host "`nAll permissions have been set successfully!" -ForegroundColor Green
}
else {
    Write-Host "`nThere were some issues setting permissions. Please check the messages above." -ForegroundColor Yellow
}
