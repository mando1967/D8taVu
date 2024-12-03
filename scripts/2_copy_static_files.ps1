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
        Invoke-WithWhatIf -Command "New-Item -ItemType Directory -Path '$dir' -Force" `
                         -Description "Creating directory: $dir" `
                         -Target $dir
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
        Invoke-WithWhatIf -Command "Copy-Item '$source' '$destination' -Force" `
                         -Description "Copying: $source -> $destination" `
                         -Target $destination
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
            Invoke-WithWhatIf -Command "Start-Process 'takeown.exe' -ArgumentList '/F `"$path`" /R /D Y' -NoNewWindow -Wait -PassThru" `
                             -Description "Taking ownership of directory: $path" `
                             -Target $path
            
            Invoke-WithWhatIf -Command "Start-Process 'icacls.exe' -ArgumentList '`"$path`" /grant:r `"$IIS_USER`":(OI)(CI)F /T /Q' -NoNewWindow -Wait -PassThru" `
                             -Description "Setting IIS user permissions on directory: $path" `
                             -Target $path
            
            Invoke-WithWhatIf -Command "Start-Process 'icacls.exe' -ArgumentList '`"$path`" /grant:r `"BUILTIN\IIS_IUSRS`":(OI)(CI)F /T /Q' -NoNewWindow -Wait -PassThru" `
                             -Description "Setting IIS_IUSRS permissions on directory: $path" `
                             -Target $path
            
            Write-ConfigLog "Set directory permissions successfully"
        } else {
            Invoke-WithWhatIf -Command "Start-Process 'takeown.exe' -ArgumentList '/F `"$path`"' -NoNewWindow -Wait -PassThru" `
                             -Description "Taking ownership of file: $path" `
                             -Target $path
            
            Invoke-WithWhatIf -Command "Start-Process 'icacls.exe' -ArgumentList '`"$path`" /grant:r `"$IIS_USER`":F /Q' -NoNewWindow -Wait -PassThru" `
                             -Description "Setting IIS user permissions on file: $path" `
                             -Target $path
            
            Invoke-WithWhatIf -Command "Start-Process 'icacls.exe' -ArgumentList '`"$path`" /grant:r `"BUILTIN\IIS_IUSRS`":F /Q' -NoNewWindow -Wait -PassThru" `
                             -Description "Setting IIS_IUSRS permissions on file: $path" `
                             -Target $path
            
            Write-ConfigLog "Set file permissions successfully"
        }
    }
    catch {
        Write-ConfigLog "Error setting permissions for $path : $_" "Error"
        if ($ABORT_ON_ERROR) { exit 1 }
    }
}

Write-ConfigLog "Restarting IIS..."
Invoke-WithWhatIf -Command "iisreset" `
                 -Description "Restarting IIS" `
                 -Target "IIS"

Write-ConfigLog "Static files copied and permissions set successfully"
