# Get the root directory (one level up from scripts)
$rootDir = Split-Path -Parent $PSScriptRoot

# Define paths
$webAppPath = "C:\inetpub\wwwroot\D8TAVu"
$envPath = "$webAppPath\env"
$user = "IIS APPPOOL\D8TAVu"

$mainPath = $webAppPath
$sitePackagesPath = "$envPath\Lib\site-packages"
$condaPath = "C:\Users\a-gon\anaconda3\Scripts\conda.exe"

Write-Host "Installing brotlicffi..."
& $condaPath install -p $envPath brotlicffi -c conda-forge -y

Write-Host "Taking ownership and setting permissions..."
& takeown /F "$sitePackagesPath" /R /D Y
& icacls.exe "$sitePackagesPath" /reset /T /Q
& icacls.exe "$sitePackagesPath" /grant:r "${user}:(OI)(CI)F" /T /Q
& icacls.exe "$sitePackagesPath" /grant:r "BUILTIN\IIS_IUSRS:(OI)(CI)F" /T /Q

Write-Host "Restarting IIS..."
iisreset

Write-Host "Permission fixes completed."
