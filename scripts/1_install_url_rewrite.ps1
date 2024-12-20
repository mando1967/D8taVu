[CmdletBinding(SupportsShouldProcess=$true)]
param()

# Import configuration
$configPath = Join-Path $PSScriptRoot "config.ps1"
if (-not (Test-Path $configPath)) {
    Write-Host "Configuration file not found: $configPath" -ForegroundColor Red
    exit 1
}
. $configPath

# Download and install URL Rewrite Module
$installerUrl = "https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi"
$installerPath = "$env:TEMP\rewrite_amd64_en-US.msi"

Write-ConfigLog "Checking URL Rewrite Module status..."

# Check if URL Rewrite Module is already installed using appcmd
$isInstalled = $false
try {
    $appcmd = "$env:windir\system32\inetsrv\appcmd.exe"
    if (Test-Path $appcmd) {
        $modules = & $appcmd list modules
        if ($modules -match "UrlRewriteModule") {
            $isInstalled = $true
        }
    }
} catch {
    Write-ConfigLog "Error checking URL Rewrite Module status: $($_.Exception.Message)" "Warning"
}

# Alternative check using registry
if (-not $isInstalled) {
    $regPath = "HKLM:\SOFTWARE\Microsoft\IIS Extensions\URL Rewrite"
    if (Test-Path $regPath) {
        $isInstalled = $true
    }
}

if ($isInstalled) {
    Write-ConfigLog "URL Rewrite Module is already installed" "Info"
} else {
    # Download the installer
    Write-ConfigLog "Downloading URL Rewrite Module installer..."
    if ($PSCmdlet.ShouldProcess($installerUrl, "Download URL Rewrite Module")) {
        try {
            Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath
            Write-ConfigLog "Download completed successfully" "Success"
        }
        catch {
            Write-ConfigLog "Error downloading URL Rewrite Module: $($_.Exception.Message)" "Error"
            if ($ABORT_ON_ERROR) { exit 1 }
        }
    } else {
        Write-ConfigLog "[WhatIf] Would download URL Rewrite Module from: $installerUrl" "Info"
        Write-ConfigLog "[WhatIf] Would save to: $installerPath" "Info"
    }
    
    # Install the module
    Write-ConfigLog "Installing URL Rewrite Module..."
    if ($PSCmdlet.ShouldProcess("URL Rewrite Module", "Install MSI")) {
        try {
            Start-Process msiexec.exe -ArgumentList "/i `"$installerPath`" /quiet /norestart" -Wait
            Write-ConfigLog "Installation completed successfully" "Success"

            # Verify installation
            Start-Sleep -Seconds 5  # Give some time for installation to complete
            $verifyPath = "HKLM:\SOFTWARE\Microsoft\IIS Extensions\URL Rewrite"
            if (Test-Path $verifyPath) {
                Write-ConfigLog "URL Rewrite Module installation verified" "Success"
            } else {
                Write-ConfigLog "URL Rewrite Module installation could not be verified" "Warning"
            }
        }
        catch {
            Write-ConfigLog "Error installing URL Rewrite Module: $($_.Exception.Message)" "Error"
            if ($ABORT_ON_ERROR) { exit 1 }
        }
    } else {
        Write-ConfigLog "[WhatIf] Would install URL Rewrite Module using msiexec" "Info"
    }
}

# Clean up installer if it exists
if (Test-Path $installerPath) {
    if ($PSCmdlet.ShouldProcess($installerPath, "Delete installer")) {
        Remove-Item $installerPath -Force
        Write-ConfigLog "Cleaned up installer file" "Info"
    }
}

# Import IIS module
Import-Module WebAdministration

Write-ConfigLog "Configuring URL Rewrite rules..."

# Function to add rewrite rule
function Add-RewriteRule {
    param(
        [string]$Name,
        [string]$Pattern,
        [string]$Action
    )
    
    $configPath = "system.webServer/rewrite/rules"
    $rulePath = "$configPath/rule[@name='$Name']"
    $webAppPath = "IIS:\Sites\$WEB_SITE_NAME\$APP_NAME"
    
    # Check if rule exists
    $existing = Get-WebConfiguration -Filter $rulePath -PSPath $webAppPath
    
    try {
        if ($existing) {
            Write-ConfigLog "Updating rewrite rule: $Name"
            if ($PSCmdlet.ShouldProcess("$Name rule", "Update URL Rewrite rule")) {
                Set-WebConfiguration -Filter "$rulePath/match/@url" -Value $Pattern -PSPath $webAppPath
                Set-WebConfiguration -Filter "$rulePath/action/@url" -Value $Action -PSPath $webAppPath
            } else {
                Write-ConfigLog "[WhatIf] Would update URL Rewrite rule: $Name" "Info"
                Write-ConfigLog "[WhatIf] Pattern: $Pattern" "Info"
                Write-ConfigLog "[WhatIf] Action: $Action" "Info"
            }
        } else {
            Write-ConfigLog "Adding new rewrite rule: $Name"
            if ($PSCmdlet.ShouldProcess("$Name rule", "Add URL Rewrite rule")) {
                Add-WebConfiguration -Filter $configPath -PSPath $webAppPath -Value @{
                    name = $Name
                    patternSyntax = "Regular Expressions"
                    stopProcessing = "True"
                }
                Set-WebConfiguration -Filter "$rulePath/match" -PSPath $webAppPath -Value @{
                    url = $Pattern
                }
                Set-WebConfiguration -Filter "$rulePath/action" -PSPath $webAppPath -Value @{
                    type = "Rewrite"
                    url = $Action
                }
            } else {
                Write-ConfigLog "[WhatIf] Would add URL Rewrite rule: $Name" "Info"
                Write-ConfigLog "[WhatIf] Pattern: $Pattern" "Info"
                Write-ConfigLog "[WhatIf] Action: $Action" "Info"
                Write-ConfigLog "[WhatIf] Pattern Syntax: Regular Expressions" "Info"
                Write-ConfigLog "[WhatIf] Stop Processing: True" "Info"
            }
        }
        Write-ConfigLog "Rule $Name configured successfully" "Success"
    }
    catch {
        Write-ConfigLog "Error configuring rule $Name : $($_.Exception.Message)" "Error"
        if ($ABORT_ON_ERROR) { exit 1 }
    }
}

# Add URL Rewrite rules
Add-RewriteRule -Name "RewriteToD8TAVu" -Pattern "^$" -Action "/D8TAVu"
Add-RewriteRule -Name "RewriteShareRequests" -Pattern "^share/(.*)" -Action "/D8TAVu/share/$1"

Write-ConfigLog "URL Rewrite Module installation and configuration completed"
