# Import WebAdministration module
Import-Module WebAdministration

# Configuration
$siteName = "Default Web Site"
$appName = "D8TAVu"
$virtualDirName = "share"
$physicalPath = "C:\Users\a-gon\OneDrive\Documents" # This is the target directory we want to access
$appPoolName = "D8TAVu"
$appPoolIdentity = "IIS AppPool\${appPoolName}"

Write-Host "Configuring virtual directory for D8TAVu..."

# Check if virtual directory exists
$virtualDirPath = "IIS:\Sites\$siteName\$appName\$virtualDirName"
if (Test-Path $virtualDirPath) {
    Write-Host "Virtual directory already exists. Removing..."
    Remove-Item $virtualDirPath -Recurse -Force
}

# Create virtual directory
Write-Host "Creating virtual directory..."
New-WebVirtualDirectory -Site $siteName -Application $appName -Name $virtualDirName -PhysicalPath $physicalPath

# Set directory permissions
Write-Host "Setting directory permissions..."
$acl = Get-Acl $physicalPath
$permission = $appPoolIdentity, "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission

# Check if permission already exists
$hasPermission = $false
foreach ($access in $acl.Access) {
    if ($access.IdentityReference.Value -eq $appPoolIdentity) {
        Write-Host "Permission already exists for $appPoolIdentity"
        $hasPermission = $true
        break
    }
}

if (-not $hasPermission) {
    $acl.AddAccessRule($accessRule)
    try {
        Set-Acl -Path $physicalPath -AclObject $acl
        Write-Host "Added ReadAndExecute permissions for $appPoolIdentity"
    }
    catch {
        Write-Host "Error setting permissions: $_"
    }
}

Write-Host "Virtual directory configuration complete!"
Write-Host "Virtual Directory URL: http://localhost/D8TAVu/$virtualDirName"
