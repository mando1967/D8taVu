[CmdletBinding(SupportsShouldProcess=$true)]
param()

# Import configuration
$configPath = Join-Path $PSScriptRoot "config.ps1"
if (-not (Test-Path $configPath)) {
    Write-Host "Configuration file not found: $configPath" -ForegroundColor Red
    exit 1
}
. $configPath

# Import IIS module
Import-Module WebAdministration

Write-ConfigLog "Setting environment variables for $APP_NAME application..."

# Function to set environment variable
function Set-FastCgiEnvironmentVariable {
    param(
        [string]$Name,
        [string]$Value
    )
    
    $configPath = "system.webServer/fastCgi/application[@fullPath='$APP_ROOT\env\Scripts\python.exe']"
    
    # Check if the environment variable already exists
    $existing = Get-WebConfiguration -Filter "$configPath/environmentVariables/environmentVariable[@name='$Name']" -PSPath "MACHINE/WEBROOT/APPHOST"
    
    if ($existing) {
        Write-ConfigLog "Updating environment variable: $Name"
        if ($PSCmdlet.ShouldProcess("$Name", "Update FastCGI environment variable")) {
            Set-WebConfiguration -Filter "$configPath/environmentVariables/environmentVariable[@name='$Name']/@value" -Value $Value -PSPath "MACHINE/WEBROOT/APPHOST"
        } else {
            Write-ConfigLog "[WhatIf] Would update FastCGI environment variable: $Name" "Info"
            Write-ConfigLog "[WhatIf] New value: $Value" "Info"
        }
    } else {
        Write-ConfigLog "Adding environment variable: $Name"
        if ($PSCmdlet.ShouldProcess("$Name", "Add FastCGI environment variable")) {
            Add-WebConfiguration -Filter "$configPath/environmentVariables" -Value @{
                name=$Name
                value=$Value
            } -PSPath "MACHINE/WEBROOT/APPHOST"
        } else {
            Write-ConfigLog "[WhatIf] Would add FastCGI environment variable: $Name" "Info"
            Write-ConfigLog "[WhatIf] Value: $Value" "Info"
        }
    }
}

# Set required environment variables
Set-FastCgiEnvironmentVariable -Name "PYTHONPATH" -Value $APP_ROOT
Set-FastCgiEnvironmentVariable -Name "WSGI_HANDLER" -Value "app.app"
Set-FastCgiEnvironmentVariable -Name "MPLCONFIGDIR" -Value "$APP_ROOT\temp"

# Create temp directory for Matplotlib if it doesn't exist
$tempDir = Join-Path $APP_ROOT "temp"
if (!(Test-Path $tempDir)) {
    Write-ConfigLog "Creating temp directory: $tempDir"
    if ($PSCmdlet.ShouldProcess($tempDir, "Create temp directory")) {
        New-Item -ItemType Directory -Path $tempDir -Force
        
        # Set permissions for temp directory
        $acl = Get-Acl $tempDir
        $permission = New-Object System.Security.AccessControl.FileSystemAccessRule($IIS_USER, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        $acl.SetAccessRule($permission)
        Set-Acl -Path $tempDir -AclObject $acl
        Write-ConfigLog "Set permissions for temp directory"
    } else {
        Write-ConfigLog "[WhatIf] Would create temp directory: $tempDir" "Info"
        Write-ConfigLog "[WhatIf] Would set FullControl permissions for $IIS_USER" "Info"
    }
}

Write-ConfigLog "Environment variables setup completed"
