# Import IIS module
Import-Module WebAdministration

# Configuration
$siteName = "Default Web Site"
$appName = "D8TAVu"
$appPath = "IIS:\Sites\$siteName\$appName"

Write-Host "Setting environment variables for D8TAVu application..."

# Function to set environment variable
function Set-FastCgiEnvironmentVariable {
    param(
        [string]$Name,
        [string]$Value
    )
    
    $configPath = "system.webServer/fastCgi/application[@fullPath='C:\inetpub\wwwroot\D8TAVu\env\Scripts\python.exe']"
    
    # Check if the environment variable already exists
    $existing = Get-WebConfiguration -Filter "$configPath/environmentVariables/environmentVariable[@name='$Name']" -PSPath "MACHINE/WEBROOT/APPHOST"
    
    if ($existing) {
        Write-Host "Updating environment variable: $Name"
        Set-WebConfiguration -Filter "$configPath/environmentVariables/environmentVariable[@name='$Name']/@value" -Value $Value -PSPath "MACHINE/WEBROOT/APPHOST"
    } else {
        Write-Host "Adding environment variable: $Name"
        Add-WebConfiguration -Filter "$configPath/environmentVariables" -Value @{
            name=$Name
            value=$Value
        } -PSPath "MACHINE/WEBROOT/APPHOST"
    }
}

# Set required environment variables
Set-FastCgiEnvironmentVariable -Name "PYTHONPATH" -Value "C:\inetpub\wwwroot\D8TAVu"
Set-FastCgiEnvironmentVariable -Name "WSGI_HANDLER" -Value "app.app"
Set-FastCgiEnvironmentVariable -Name "MPLCONFIGDIR" -Value "C:\inetpub\wwwroot\D8TAVu\temp"

# Create temp directory for Matplotlib if it doesn't exist
$tempDir = "C:\inetpub\wwwroot\D8TAVu\temp"
if (!(Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force
    
    # Set permissions for temp directory
    $acl = Get-Acl $tempDir
    $appPoolIdentity = "IIS APPPOOL\D8TAVu"
    $permission = New-Object System.Security.AccessControl.FileSystemAccessRule($appPoolIdentity, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($permission)
    Set-Acl -Path $tempDir -AclObject $acl
}

Write-Host "Environment variables configured successfully!"
