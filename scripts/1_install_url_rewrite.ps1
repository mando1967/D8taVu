# Download and install URL Rewrite Module
$installerUrl = "https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi"
$installerPath = "$env:TEMP\rewrite_amd64_en-US.msi"

Write-Host "Installing URL Rewrite Module..."

# Check if URL Rewrite Module is already installed
$rewriteModule = Get-WebModule -Name "UrlRewrite"
if ($rewriteModule) {
    Write-Host "URL Rewrite Module is already installed"
} else {
    # Download the installer
    Write-Host "Downloading URL Rewrite Module installer..."
    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath
    
    # Install the module
    Write-Host "Installing URL Rewrite Module..."
    Start-Process msiexec.exe -ArgumentList "/i `"$installerPath`" /quiet /norestart" -Wait
    
    # Clean up
    Remove-Item $installerPath -Force
}

# Import IIS module
Import-Module WebAdministration

# Configuration
$siteName = "Default Web Site"
$appName = "D8TAVu"

Write-Host "Configuring URL Rewrite rules..."

# Function to add rewrite rule
function Add-RewriteRule {
    param(
        [string]$Name,
        [string]$Pattern,
        [string]$Action
    )
    
    $configPath = "system.webServer/rewrite/rules"
    $rulePath = "$configPath/rule[@name='$Name']"
    
    # Check if rule exists
    $existing = Get-WebConfiguration -Filter $rulePath -PSPath "IIS:\Sites\$siteName\$appName"
    
    if ($existing) {
        Write-Host "Updating rewrite rule: $Name"
        Set-WebConfiguration -Filter "$rulePath/match/@url" -Value $Pattern -PSPath "IIS:\Sites\$siteName\$appName"
        Set-WebConfiguration -Filter "$rulePath/action/@url" -Value $Action -PSPath "IIS:\Sites\$siteName\$appName"
    } else {
        Write-Host "Adding rewrite rule: $Name"
        Add-WebConfiguration -Filter $configPath -Value @{
            name=$Name
            patternSyntax="ECMAScript"
            stopProcessing="True"
        } -PSPath "IIS:\Sites\$siteName\$appName"
        
        Set-WebConfiguration -Filter "$rulePath/match" -Value @{
            url=$Pattern
        } -PSPath "IIS:\Sites\$siteName\$appName"
        
        Set-WebConfiguration -Filter "$rulePath/action" -Value @{
            type="Rewrite"
            url=$Action
        } -PSPath "IIS:\Sites\$siteName\$appName"
    }
}

# Add rewrite rules
Add-RewriteRule -Name "RewriteToD8TAVu" -Pattern "^$" -Action "/D8TAVu"
Add-RewriteRule -Name "RewriteShareRequests" -Pattern "^share/(.*)" -Action "/D8TAVu/share/$1"

Write-Host "URL Rewrite Module installation and configuration complete!"
