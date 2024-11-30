# Define paths
$envPath = "C:\inetpub\wwwroot\D8TAVu\env"
$appPoolName = "D8TAVu"
$appPoolIdentity = "IIS APPPOOL\$appPoolName"
$sitePackagesPath = "$envPath\Lib\site-packages"

# Function to set permissions
function Set-FilePermissions {
    param (
        [string]$Path
    )
    
    if (Test-Path $Path) {
        Write-Host "Setting permissions for $Path..." -ForegroundColor Green
        
        try {
            # Different handling for files and directories
            if ((Get-Item $Path) -is [System.IO.DirectoryInfo]) {
                # For directories, use /R /D Y
                $result = Start-Process "takeown.exe" -ArgumentList "/F `"$Path`" /R /D Y" -NoNewWindow -Wait -PassThru
                $result = Start-Process "icacls.exe" -ArgumentList "`"$Path`" /grant:r `"$appPoolIdentity`":(OI)(CI)F /T /Q" -NoNewWindow -Wait -PassThru
                $result = Start-Process "icacls.exe" -ArgumentList "`"$Path`" /grant:r `"BUILTIN\IIS_IUSRS`":(OI)(CI)F /T /Q" -NoNewWindow -Wait -PassThru
            } else {
                # For single files, use simpler command
                Write-Host "Taking ownership of file $Path"
                $result = Start-Process "takeown.exe" -ArgumentList "/F `"$Path`"" -NoNewWindow -Wait -PassThru
                
                Write-Host "Setting permissions for file $Path"
                $result = Start-Process "icacls.exe" -ArgumentList "`"$Path`" /grant:r `"$appPoolIdentity`":F /Q" -NoNewWindow -Wait -PassThru
                $result = Start-Process "icacls.exe" -ArgumentList "`"$Path`" /grant:r `"BUILTIN\IIS_IUSRS`":F /Q" -NoNewWindow -Wait -PassThru
            }
            
            # Verify permissions
            Write-Host "Verifying permissions for $Path..." -ForegroundColor Cyan
            $acl = Get-Acl $Path
            $acl.Access | Where-Object { 
                $_.IdentityReference -match "IIS APPPOOL|IIS_IUSRS" 
            } | Format-Table IdentityReference, FileSystemRights
        }
        catch {
            Write-Host "Error processing $Path : $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Path not found: $Path" -ForegroundColor Yellow
    }
}

# First set permissions on the site-packages directory itself
Write-Host "Setting permissions for site-packages directory..."
Set-FilePermissions -Path $sitePackagesPath

# Handle specific files that need direct permission setting
Write-Host "Setting permissions for specific files..." -ForegroundColor Cyan
$specificFiles = @(
    "$sitePackagesPath\brotli.py",
    "$sitePackagesPath\appdirs.py",
    "$sitePackagesPath\_brotli.cp39-win_amd64.pyd"
)

foreach ($file in $specificFiles) {
    if (Test-Path $file) {
        Write-Host "Found $file" -ForegroundColor Green
        # For these specific files, use direct file system commands
        Write-Host "Taking ownership of $file"
        $owner = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $acl = Get-Acl $file
        $acl.SetOwner([System.Security.Principal.NTAccount]$owner)
        Set-Acl $file $acl

        Write-Host "Setting permissions for $file"
        $acl = Get-Acl $file
        $accessRule1 = New-Object System.Security.AccessControl.FileSystemAccessRule($appPoolIdentity, "FullControl", "Allow")
        $accessRule2 = New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\IIS_IUSRS", "FullControl", "Allow")
        $acl.AddAccessRule($accessRule1)
        $acl.AddAccessRule($accessRule2)
        Set-Acl $file $acl

        Write-Host "Permissions set for $file" -ForegroundColor Green
    } else {
        Write-Host "$file not found" -ForegroundColor Yellow
    }
}

# Set permissions on all Python-related files in site-packages
Write-Host "Setting permissions for all Python-related files..."
$extensions = @("*.py", "*.pyd", "*.dll", "*.so")
foreach ($ext in $extensions) {
    Get-ChildItem -Path $sitePackagesPath -Filter $ext -Recurse | ForEach-Object {
        if ($_.FullName -notin $specificFiles) {  # Skip files we already processed
            Set-FilePermissions -Path $_.FullName
        }
    }
}

# Handle critical package directories
$criticalPackages = @(
    "yfinance",
    "urllib3",
    "requests",
    "pandas",
    "numpy",
    "brotli",
    "appdirs"
)

foreach ($package in $criticalPackages) {
    $packagePath = Join-Path $sitePackagesPath $package
    if (Test-Path $packagePath) {
        Write-Host "Setting permissions for $package package..." -ForegroundColor Cyan
        Set-FilePermissions -Path $packagePath
    }
}

# Restart IIS to apply changes
Write-Host "Restarting IIS..."
iisreset

Write-Host "Script completed. Please check the web application now." -ForegroundColor Green
