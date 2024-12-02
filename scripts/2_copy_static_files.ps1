# Import configuration
$configPath = Join-Path $PSScriptRoot "config.ps1"
if (-not (Test-Path $configPath)) {
    Write-Host "Configuration file not found: $configPath" -ForegroundColor Red
    exit 1
}
. $configPath

# Define paths
$sourcePath = Split-Path -Parent $PSScriptRoot
$destPath = $APP_ROOT

# Create directories if they don't exist
$directories = @(
    (Join-Path $destPath "static"),
    (Join-Path $destPath "static\js"),
    (Join-Path $destPath "templates")
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        Write-ConfigLog "Creating directory: $dir"
        New-Item -ItemType Directory -Path $dir -Force
    }
}

# Copy files
Write-ConfigLog "Copying static files..."
$filesToCopy = @{
    (Join-Path $sourcePath "static\js\app.js") = (Join-Path $destPath "static\js\app.js")
    (Join-Path $sourcePath "templates\index.html") = (Join-Path $destPath "templates\index.html")
}

foreach ($source in $filesToCopy.Keys) {
    $destination = $filesToCopy[$source]
    if (Test-Path $source) {
        Copy-Item $source $destination -Force
        Write-ConfigLog "Copied: $source -> $destination"
    } else {
        Write-ConfigLog "Source file not found: $source" "Warning"
    }
}

# Set permissions
$paths = @(
    (Join-Path $destPath "static"),
    (Join-Path $destPath "templates"),
    (Join-Path $destPath "static\js\app.js"),
    (Join-Path $destPath "templates\index.html")
)

foreach ($path in $paths) {
    Write-ConfigLog "Setting permissions for: $path"
    
    try {
        # Take ownership
        if ((Get-Item $path) -is [System.IO.DirectoryInfo]) {
            $result = Start-Process "takeown.exe" -ArgumentList "/F `"$path`" /R /D Y" -NoNewWindow -Wait -PassThru
            if ($result.ExitCode -eq 0) {
                $result = Start-Process "icacls.exe" -ArgumentList "`"$path`" /grant:r `"$IIS_USER`":(OI)(CI)F /T /Q" -NoNewWindow -Wait -PassThru
                $result = Start-Process "icacls.exe" -ArgumentList "`"$path`" /grant:r `"BUILTIN\IIS_IUSRS`":(OI)(CI)F /T /Q" -NoNewWindow -Wait -PassThru
                Write-ConfigLog "Set directory permissions successfully"
            } else {
                Write-ConfigLog "Failed to take ownership of directory: $path" "Error"
            }
        } else {
            $result = Start-Process "takeown.exe" -ArgumentList "/F `"$path`"" -NoNewWindow -Wait -PassThru
            if ($result.ExitCode -eq 0) {
                $result = Start-Process "icacls.exe" -ArgumentList "`"$path`" /grant:r `"$IIS_USER`":F /Q" -NoNewWindow -Wait -PassThru
                $result = Start-Process "icacls.exe" -ArgumentList "`"$path`" /grant:r `"BUILTIN\IIS_IUSRS`":F /Q" -NoNewWindow -Wait -PassThru
                Write-ConfigLog "Set file permissions successfully"
            } else {
                Write-ConfigLog "Failed to take ownership of file: $path" "Error"
            }
        }
    }
    catch {
        Write-ConfigLog "Error setting permissions for $path : $_" "Error"
        if ($ABORT_ON_ERROR) { exit 1 }
    }
}

Write-ConfigLog "Restarting IIS..."
iisreset

Write-ConfigLog "Static files copied and permissions set successfully"
