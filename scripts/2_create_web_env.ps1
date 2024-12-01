[CmdletBinding()]
param(
    [Parameter()]
    [switch]$CheckPermissionsOnly
)

# Get the root directory (one level up from scripts)
$rootDir = Split-Path -Parent $PSScriptRoot

# Create environment in web app directory
$webAppPath = "C:\inetpub\wwwroot\D8TAVu"
$envYamlPath = Join-Path $rootDir "environment.yml"
$envPath = "$webAppPath\env"
$user = "IIS APPPOOL\D8TAVu"

# Source and destination paths for app files
$sourceAppPath = $rootDir
$iisAppPath = "C:\inetpub\wwwroot\D8TAVu"

# Function to verify permissions
function Test-DirectoryPermissions {
    param (
        [string]$path,
        [string]$user
    )
    
    try {
        Write-Host "`nChecking permissions for $path..."
        $acl = Get-Acl -Path $path
        $userHasFullControl = $false
        
        foreach ($access in $acl.Access) {
            if ($access.IdentityReference.Value -eq $user -and 
                $access.FileSystemRights -match "FullControl") {
                $userHasFullControl = $true
                break
            }
        }
        
        if ($userHasFullControl) {
            Write-Host " $user has FullControl permissions on $path" -ForegroundColor Green
            return $true
        } else {
            Write-Host " $user does NOT have FullControl permissions on $path" -ForegroundColor Red
            Write-Host "Current permissions:"
            $acl.Access | Format-Table IdentityReference, FileSystemRights -AutoSize
            return $false
        }
    }
    catch {
        Write-Host "Error checking permissions for $path : $_" -ForegroundColor Red
        return $false
    }
}

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

# Function to copy app files
function Copy-AppFiles {
    param (
        [string]$source,
        [string]$destination
    )
    
    try {
        Write-Host "`nCopying app files from $source to $destination..."
        
        # Create destination if it doesn't exist
        if (-not (Test-Path $destination)) {
            New-Item -ItemType Directory -Path $destination -Force | Out-Null
        }
        
        # Copy all files except env directory and any existing web.config
        Get-ChildItem -Path $source -Exclude "env","web.config" | ForEach-Object {
            if ($_.PSIsContainer) {
                Copy-Item -Path $_.FullName -Destination $destination -Recurse -Force
            } else {
                Copy-Item -Path $_.FullName -Destination $destination -Force
            }
        }
        
        Write-Host "Successfully copied app files" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Error copying app files: $_" -ForegroundColor Red
        return $false
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

# Function to verify permissions using icacls
function Test-IcaclsPermissions {
    param (
        [string]$path,
        [string]$user
    )
    
    try {
        Write-Host "`nChecking permissions for $path..."
        $acls = & icacls.exe $path
        $userHasFullControl = $false
        
        foreach ($acl in $acls) {
            if ($acl -match [regex]::Escape($user) -and $acl -match "F") {
                $userHasFullControl = $true
                break
            }
        }
        
        if ($userHasFullControl) {
            Write-Host " $user has FullControl permissions on $path" -ForegroundColor Green
            return $true
        } else {
            Write-Host " $user does NOT have FullControl permissions on $path" -ForegroundColor Red
            Write-Host "Current permissions:"
            $acls | ForEach-Object { Write-Host $_ }
            return $false
        }
    }
    catch {
        Write-Host "Error checking permissions for $path : $_" -ForegroundColor Red
        return $false
    }
}

# Function to verify all directory permissions
function Test-AllDirectoryPermissions {
    $mainDirs = @(
        $envPath,
        "$envPath\Lib",
        "$envPath\Lib\site-packages",
        "$envPath\Lib\site-packages\pandas",
        "$envPath\Scripts",
        $iisAppPath
    )

    # Add pandas directory and all its contents
    if (Test-Path "$envPath\Lib\site-packages\pandas") {
        $mainDirs += "$envPath\Lib\site-packages\pandas"
    }

    $verificationSuccess = $true
    Write-Host "`nVerifying permissions..."
    foreach ($dir in $mainDirs) {
        if (Test-Path $dir) {
            Remove-ReadOnlyAttribute -path $dir
            if (-not (Test-IcaclsPermissions -path $dir -user $user)) {
                $verificationSuccess = $false
            }
        }
        else {
            Write-Host "Directory not found: $dir" -ForegroundColor Red
            $verificationSuccess = $false
        }
    }
    return $verificationSuccess
}

# If CheckPermissionsOnly is specified, only verify permissions and exit
if ($CheckPermissionsOnly) {
    $verificationSuccess = Test-AllDirectoryPermissions
    if ($verificationSuccess) {
        Write-Host "`nAll permissions are correctly set!" -ForegroundColor Green
    }
    else {
        Write-Host "`nSome permissions need to be corrected. See details above." -ForegroundColor Yellow
    }
    exit
}

# Rest of the script for environment creation...
# Check if environment already exists
if (Test-Path $envPath) {
    $response = Read-Host "Environment already exists at $envPath. Do you want to remove it and create a new one? (y/n)"
    if ($response -eq 'y') {
        Write-Host "Removing existing environment..."
        try {
            # Remove read-only attributes if any
            Get-ChildItem -Path $envPath -Recurse -Force | ForEach-Object {
                Remove-ReadOnlyAttribute -path $_.FullName
            }
            Remove-Item -Path $envPath -Recurse -Force
            Write-Host "Existing environment removed successfully."
        }
        catch {
            Write-Host "Error removing existing environment: $_"
            exit 1
        }
    }
    else {
        Write-Host "Operation cancelled by user."
        exit 0
    }
}

# Create directory if it doesn't exist
if (-not (Test-Path $webAppPath)) {
    New-Item -ItemType Directory -Path $webAppPath -Force
}

# Create the conda environment
Write-Host "`nCreating conda environment..."
try {
    & "C:\Users\a-gon\anaconda3\Scripts\conda.exe" env create -f $envYamlPath -p $envPath
    if ($LASTEXITCODE -ne 0) {
        throw "Conda environment creation failed with exit code $LASTEXITCODE"
    }
}
catch {
    Write-Host "Error creating conda environment: $_"
    exit 1
}

# Set up application files
Write-Host "`nSetting up application files..."
if (-not (Copy-AppFiles -source $sourceAppPath -destination $iisAppPath)) {
    Write-Host "Failed to copy application files" -ForegroundColor Red
    exit 1
}

# Set permissions on main directories
$mainDirs = @(
    $envPath,
    "$envPath\Lib",
    "$envPath\Lib\site-packages",
    "$envPath\Lib\site-packages\pandas",
    "$envPath\Scripts",
    $iisAppPath
)

$success = $true
foreach ($dir in $mainDirs) {
    if (Test-Path $dir) {
        Remove-ReadOnlyAttribute -path $dir
        if (-not (Set-IcaclsPermissions -path $dir -user $user)) {
            $success = $false
        }
    }
    else {
        Write-Host "Directory not found: $dir" -ForegroundColor Red
        $success = $false
    }
}

# Verify permissions
$verificationSuccess = Test-AllDirectoryPermissions

if ($success -and $verificationSuccess) {
    Write-Host "`nEnvironment created and permissions set successfully!" -ForegroundColor Green
    Write-Host "Next steps:"
    Write-Host "1. Update your web.config to use the new environment path:"
    Write-Host "   $envPath\python.exe"
    Write-Host "2. Restart the IIS application pool"
}
else {
    Write-Host "`nEnvironment was created but there were some issues with permissions." -ForegroundColor Yellow
    Write-Host "Please check the messages above for details."
    Write-Host "You may need to run the script again or set permissions manually."
}
