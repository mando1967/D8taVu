# Define paths
$sourcePath = "C:\Users\a-gon\OneDrive\Documents\python\CascadeProjects\windsurf-project\D8TAVu"
$destPath = "C:\inetpub\wwwroot\D8TAVu"
$appPoolName = "D8TAVu"
$appPoolIdentity = "IIS APPPOOL\$appPoolName"

# Create directories if they don't exist
$directories = @(
    "$destPath\static",
    "$destPath\static\js",
    "$destPath\templates"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        Write-Host "Creating directory: $dir"
        New-Item -ItemType Directory -Path $dir -Force
    }
}

# Copy files
Write-Host "Copying static files..."
Copy-Item "$sourcePath\static\js\app.js" "$destPath\static\js\app.js" -Force
Copy-Item "$sourcePath\templates\index.html" "$destPath\templates\index.html" -Force

# Set permissions
$paths = @(
    "$destPath\static",
    "$destPath\templates",
    "$destPath\static\js\app.js",
    "$destPath\templates\index.html"
)

foreach ($path in $paths) {
    Write-Host "Setting permissions for: $path"
    
    # Take ownership
    if ((Get-Item $path) -is [System.IO.DirectoryInfo]) {
        $result = Start-Process "takeown.exe" -ArgumentList "/F `"$path`" /R /D Y" -NoNewWindow -Wait -PassThru
        $result = Start-Process "icacls.exe" -ArgumentList "`"$path`" /grant:r `"$appPoolIdentity`":(OI)(CI)F /T /Q" -NoNewWindow -Wait -PassThru
        $result = Start-Process "icacls.exe" -ArgumentList "`"$path`" /grant:r `"BUILTIN\IIS_IUSRS`":(OI)(CI)F /T /Q" -NoNewWindow -Wait -PassThru
    } else {
        $result = Start-Process "takeown.exe" -ArgumentList "/F `"$path`"" -NoNewWindow -Wait -PassThru
        $result = Start-Process "icacls.exe" -ArgumentList "`"$path`" /grant:r `"$appPoolIdentity`":F /Q" -NoNewWindow -Wait -PassThru
        $result = Start-Process "icacls.exe" -ArgumentList "`"$path`" /grant:r `"BUILTIN\IIS_IUSRS`":F /Q" -NoNewWindow -Wait -PassThru
    }
}

Write-Host "Restarting IIS..."
iisreset

Write-Host "Static files copied and permissions set."
