# Define paths and users
$appPoolName = "D8TAVu"
$appPoolIdentity = "IIS APPPOOL\$appPoolName"
$iisUsers = "BUILTIN\IIS_IUSRS"

$mainPath = "C:\inetpub\wwwroot\D8TAVu"
$sitePackagesPath = "$mainPath\env\Lib\site-packages"
$condaPath = "C:\Users\a-gon\anaconda3\Scripts\conda.exe"
$envPath = "C:\inetpub\wwwroot\D8TAVu\env"

Write-Host "Installing brotlicffi..."
& $condaPath install -p $envPath brotlicffi -c conda-forge -y

Write-Host "Taking ownership and setting permissions..."
& takeown /F "$sitePackagesPath" /R /D Y
& icacls.exe "$sitePackagesPath" /reset /T /Q
& icacls.exe "$sitePackagesPath" /grant:r "${appPoolIdentity}:(OI)(CI)F" /T /Q
& icacls.exe "$sitePackagesPath" /grant:r "${iisUsers}:(OI)(CI)F" /T /Q

Write-Host "Restarting IIS..."
iisreset

Write-Host "Permission fixes completed."
