[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter()]
    [switch]$CheckPermissionsOnly
)

# Import configuration
$configPath = Join-Path $PSScriptRoot "config.ps1"
if (-not (Test-Path $configPath)) {
    Write-Host "Configuration file not found: $configPath" -ForegroundColor Red
    exit 1
}
. $configPath

# Get the root directory (one level up from scripts)
$rootDir = Split-Path -Parent $PSScriptRoot

# Create environment in web app directory
$webAppPath = $APP_ROOT
$envYamlPath = Join-Path $rootDir "environment.yml"
$envPath = "$webAppPath\env"
$user = $IIS_USER

# Source and destination paths for app files
$sourceAppPath = $rootDir
$iisAppPath = $APP_ROOT

# Function to verify permissions
function Test-DirectoryPermissions {
    param (
        [string]$path,
        [string]$user
    )
    
    try {
        Write-ConfigLog "Checking permissions for $path..."
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
            Write-ConfigLog "$user has FullControl permissions on $path" "Success"
            return $true
        } else {
            Write-ConfigLog "$user does NOT have FullControl permissions on $path" "Error"
            Write-ConfigLog "Current permissions:"
            $acl.Access | Format-Table IdentityReference, FileSystemRights -AutoSize
            return $false
        }
    }
    catch {
        Write-ConfigLog "Error checking permissions for $path : $_" "Error"
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
            if ($PSCmdlet.ShouldProcess($destination, "Create Directory")) {
                New-Item -ItemType Directory -Path $destination -Force | Out-Null
            } else {
                Write-ConfigLog "[WhatIf] Would create directory: $destination" "Info"
            }
        }
        
        # Copy all files except env directory and any existing web.config
        Get-ChildItem -Path $source -Exclude "env","web.config" | ForEach-Object {
            if ($_.PSIsContainer) {
                if ($PSCmdlet.ShouldProcess($_.FullName, "Copy Directory to $destination")) {
                    Copy-Item -Path $_.FullName -Destination $destination -Recurse -Force
                } else {
                    Write-ConfigLog "[WhatIf] Would copy directory: $($_.FullName) to $destination" "Info"
                }
            } else {
                if ($PSCmdlet.ShouldProcess($_.FullName, "Copy File to $destination")) {
                    Copy-Item -Path $_.FullName -Destination $destination -Force
                } else {
                    Write-ConfigLog "[WhatIf] Would copy file: $($_.FullName) to $destination" "Info"
                }
            }
        }
        
        Write-Host "Successfully copied app files" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Error copying app files: $($_.Exception.Message)" -ForegroundColor Red
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
        if ($PSCmdlet.ShouldProcess($path, "Set ICACLS permissions for $user")) {
            $result = Start-Process "icacls.exe" -ArgumentList "`"$path`" /grant `"$user`":(OI)(CI)F /T /Q" -NoNewWindow -Wait -PassThru
            if ($result.ExitCode -eq 0) {
                Write-Host "Successfully set permissions for $path" -ForegroundColor Green
                return $true
            } else {
                Write-Host "Failed to set permissions for $path. Exit code: $($result.ExitCode)" -ForegroundColor Red
                return $false
            }
        } else {
            Write-ConfigLog "[WhatIf] Would set ICACLS permissions for $user on $path" "Info"
            return $true
        }
    }
    catch {
        Write-Host "Error setting permissions for $path : $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to verify icacls permissions
function Test-IcaclsPermissions {
    param (
        [string]$path,
        [string]$user
    )
    
    try {
        Write-ConfigLog "Checking icacls permissions for $path..."
        $icaclsOutput = icacls $path
        
        if ($icaclsOutput -match [regex]::Escape($user)) {
            Write-ConfigLog "Found $user in icacls output for $path" "Success"
            return $true
        } else {
            Write-ConfigLog "$user not found in icacls output for $path" "Error"
            Write-ConfigLog "Current icacls:"
            Write-ConfigLog $icaclsOutput
            return $false
        }
    }
    catch {
        Write-ConfigLog "Error checking icacls permissions for $path : $_" "Error"
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

# Only check permissions if flag is set
if ($CheckPermissionsOnly) {
    Write-ConfigLog "Checking permissions only..."
    $permissionsOk = Test-DirectoryPermissions -path $APP_ROOT -user $IIS_USER
    $icaclsOk = Test-IcaclsPermissions -path $APP_ROOT -user $IIS_USER
    
    if ($permissionsOk -and $icaclsOk) {
        Write-ConfigLog "All permissions are correctly set" "Success"
        exit 0
    } else {
        Write-ConfigLog "Permissions check failed" "Error"
        exit 1
    }
}

# Create environment
Write-ConfigLog "Creating Python environment in $APP_ROOT..."

# Verify environment.yml exists
$envYamlPath = Join-Path $rootDir "environment.yml"
if (-not (Test-Path $envYamlPath)) {
    Write-ConfigLog "environment.yml not found at: $envYamlPath" "Error"
    exit 1
}

# Create environment using conda
$success = $false
try {
    # Activate conda
    Write-ConfigLog "Activating Conda..."
    $condaPath = Join-Path $CONDA_PATH "Scripts\activate.bat"
    if (-not (Test-Path $condaPath)) {
        Write-ConfigLog "Conda activation script not found at: $condaPath" "Error"
        exit 1
    }
    
    # Create environment
    Write-ConfigLog "Creating environment from $envYamlPath..."
    $envPath = Join-Path $APP_ROOT "env"
    if ($PSCmdlet.ShouldProcess($envPath, "Create Conda environment")) {
        & $condaPath
        conda env create -f $envYamlPath -p $envPath
        if ($LASTEXITCODE -eq 0) {
            Write-ConfigLog "Environment created successfully" "Success"
            $success = $true
        } else {
            Write-ConfigLog "Failed to create environment" "Error"
        }
    } else {
        Write-ConfigLog "[WhatIf] Would create Conda environment at: $envPath" "Info"
        Write-ConfigLog "[WhatIf] Would use environment.yml from: $envYamlPath" "Info"
        $success = $true
    }
}
catch {
    Write-ConfigLog "Error creating environment: $($_.Exception.Message)" "Error"
}

# Verify permissions after creation
$verificationSuccess = $false
if ($success) {
    Write-ConfigLog "Verifying permissions..."
    $permissionsOk = Test-DirectoryPermissions -path $APP_ROOT -user $IIS_USER
    $icaclsOk = Test-IcaclsPermissions -path $APP_ROOT -user $IIS_USER
    $verificationSuccess = $permissionsOk -and $icaclsOk
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

if ($success -and $verificationSuccess) {
    Write-ConfigLog "Environment created and permissions set successfully!" "Success"
    Write-Host "`nEnvironment created and permissions set successfully!" -ForegroundColor Green
    Write-Host "Next steps:"
    Write-Host "1. Update your web.config to use the new environment path:"
    Write-Host "   $envPath\python.exe"
    Write-Host "2. Make sure the application pool identity has access to the environment"
    Write-Host "3. Restart IIS using scripts\restart_iis.ps1"
} else {
    Write-ConfigLog "Environment setup failed. Please check the logs for details." "Error"
    Write-Host "`nEnvironment was created but there were some issues with permissions." -ForegroundColor Yellow
    Write-Host "Please check the messages above for details."
    Write-Host "You may need to run the script again or set permissions manually."
    exit 1
}
