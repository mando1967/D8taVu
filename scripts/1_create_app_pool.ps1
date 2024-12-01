# Import IIS module
Import-Module WebAdministration

# Configuration
$appPoolName = "D8TAVu"
$siteName = "Default Web Site"
$appName = "D8TAVu"
$physicalPath = "C:\inetpub\wwwroot\D8TAVu"

Write-Host "Creating and configuring IIS Application Pool and Web Application..."

# Create Application Pool if it doesn't exist
if (!(Test-Path "IIS:\AppPools\$appPoolName")) {
    Write-Host "Creating Application Pool: $appPoolName"
    New-WebAppPool -Name $appPoolName
    
    # Configure App Pool Settings
    $appPool = Get-IISAppPool -Name $appPoolName
    
    # Set to No Managed Code
    Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name "managedRuntimeVersion" -Value ""
    
    # Set identity to ApplicationPoolIdentity
    Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name "processModel.identityType" -Value 4
    
    # Enable 32-bit applications
    Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name "enable32BitAppOnWin64" -Value $true
    
    Write-Host "Application Pool configured successfully"
} else {
    Write-Host "Application Pool $appPoolName already exists"
}

# Create Web Application if it doesn't exist
$webAppPath = "IIS:\Sites\$siteName\$appName"
if (!(Test-Path $webAppPath)) {
    Write-Host "Creating Web Application: $appName"
    New-WebApplication -Name $appName -Site $siteName -PhysicalPath $physicalPath -ApplicationPool $appPoolName -Force
    
    # Configure FastCGI Handler Mapping
    Add-WebConfiguration -Filter "system.webServer/handlers" -PSPath $webAppPath -Value @{
        name="Python_via_FastCGI"
        path="*"
        verb="*"
        modules="FastCgiModule"
        scriptProcessor="C:\inetpub\wwwroot\D8TAVu\env\Scripts\python.exe|C:\inetpub\wwwroot\D8TAVu\env\Lib\site-packages\wfastcgi.py"
        resourceType="Unspecified"
    }
    
    Write-Host "Web Application created and configured successfully"
} else {
    Write-Host "Web Application $appName already exists"
}

Write-Host "Configuration complete!"
