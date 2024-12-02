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

Write-ConfigLog "Installing URL Rewrite Module..."

# Check if URL Rewrite Module is already installed
$rewriteModule = Get-WebModule -Name "UrlRewrite"
if ($rewriteModule) {
    Write-ConfigLog "URL Rewrite Module is already installed" "Info"
} else {
    # Download the installer
    Write-ConfigLog "Downloading URL Rewrite Module installer..."
    try {
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath
        Write-ConfigLog "Download completed successfully" "Success"
    }
    catch {
        Write-ConfigLog "Error downloading URL Rewrite Module: $_" "Error"
        if ($ABORT_ON_ERROR) { exit 1 }
    }
    
    # Install the module
    Write-ConfigLog "Installing URL Rewrite Module..."
    try {
        Start-Process msiexec.exe -ArgumentList "/i `"$installerPath`" /quiet /norestart" -Wait
        Write-ConfigLog "Installation completed successfully" "Success"
    }
    catch {
        Write-ConfigLog "Error installing URL Rewrite Module: $_" "Error"
        if ($ABORT_ON_ERROR) { exit 1 }
    }
    
    # Clean up
    Remove-Item $installerPath -Force
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
            Set-WebConfiguration -Filter "$rulePath/match/@url" -Value $Pattern -PSPath $webAppPath
            Set-WebConfiguration -Filter "$rulePath/action/@url" -Value $Action -PSPath $webAppPath
        } else {
            Write-ConfigLog "Adding new rewrite rule: $Name"
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
        }
        Write-ConfigLog "Rule $Name configured successfully" "Success"
    }
    catch {
        Write-ConfigLog "Error configuring rule $Name : $_" "Error"
        if ($ABORT_ON_ERROR) { exit 1 }
    }
}

# Add URL Rewrite rules
Add-RewriteRule -Name "RewriteToD8TAVu" -Pattern "^$" -Action "/D8TAVu"
Add-RewriteRule -Name "RewriteShareRequests" -Pattern "^share/(.*)" -Action "/D8TAVu/share/$1"

Write-ConfigLog "URL Rewrite Module installation and configuration completed"
