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

Write-ConfigLog "Creating and configuring IIS Application Pool and Web Application..."

# Create Application Pool if it doesn't exist
if (!(Test-Path "IIS:\AppPools\$APP_NAME")) {
    Write-ConfigLog "Creating Application Pool: $APP_NAME"
    if ($PSCmdlet.ShouldProcess($APP_NAME, "Create Application Pool")) {
        New-WebAppPool -Name $APP_NAME
        
        # Configure App Pool Settings
        Write-ConfigLog "Configuring Application Pool settings..."
        
        # Set to No Managed Code
        Set-ItemProperty "IIS:\AppPools\$APP_NAME" -Name "managedRuntimeVersion" -Value ""
        
        # Set identity to ApplicationPoolIdentity
        Set-ItemProperty "IIS:\AppPools\$APP_NAME" -Name "processModel.identityType" -Value 4
        
        # Enable 32-bit applications
        Set-ItemProperty "IIS:\AppPools\$APP_NAME" -Name "enable32BitAppOnWin64" -Value $true
        
        Write-ConfigLog "Application Pool configured successfully" "Success"
    } else {
        Write-ConfigLog "[WhatIf] Would create Application Pool: $APP_NAME" "Info"
        Write-ConfigLog "[WhatIf] Would set managedRuntimeVersion to empty string" "Info"
        Write-ConfigLog "[WhatIf] Would set identityType to ApplicationPoolIdentity" "Info"
        Write-ConfigLog "[WhatIf] Would enable 32-bit applications" "Info"
    }
} else {
    Write-ConfigLog "Application Pool $APP_NAME already exists" "Info"
}

# Create Web Application if it doesn't exist
$webAppPath = "IIS:\Sites\$WEB_SITE_NAME\$APP_NAME"
if (!(Test-Path $webAppPath)) {
    Write-ConfigLog "Creating Web Application: $APP_NAME"
    if ($PSCmdlet.ShouldProcess($APP_NAME, "Create Web Application")) {
        New-WebApplication -Name $APP_NAME -Site $WEB_SITE_NAME -PhysicalPath $APP_ROOT -ApplicationPool $APP_NAME -Force
        
        # Configure FastCGI Handler Mapping
        Write-ConfigLog "Configuring FastCGI Handler Mapping..."
        $pythonPath = Join-Path $APP_ROOT "env\Scripts\python.exe"
        $wfastcgiPath = Join-Path $APP_ROOT "env\Lib\site-packages\wfastcgi.py"
        
        try {
            Add-WebConfiguration -Filter "system.webServer/handlers" -PSPath $webAppPath -Value @{
                name="Python_via_FastCGI"
                path="*"
                verb="*"
                modules="FastCgiModule"
                scriptProcessor="$pythonPath|$wfastcgiPath"
                resourceType="Unspecified"
            }
            Write-ConfigLog "FastCGI Handler Mapping configured successfully" "Success"
        }
        catch {
            Write-ConfigLog "Error configuring FastCGI Handler Mapping: $($_.Exception.Message)" "Error"
            if ($ABORT_ON_ERROR) { exit 1 }
        }
        
        Write-ConfigLog "Web Application created and configured successfully" "Success"
    } else {
        Write-ConfigLog "[WhatIf] Would create Web Application: $APP_NAME" "Info"
        Write-ConfigLog "[WhatIf] Would configure FastCGI Handler Mapping" "Info"
    }
} else {
    Write-ConfigLog "Web Application $APP_NAME already exists" "Info"
}

Write-ConfigLog "IIS Application Pool and Web Application setup completed"
