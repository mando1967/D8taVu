[CmdletBinding(SupportsShouldProcess=$true)]
param()

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
if ($PSCmdlet.ShouldProcess("brotlicffi", "Install package using conda")) {
    & $condaPath install -p $envPath brotlicffi -c conda-forge -y
} else {
    Write-Host "[WhatIf] Would install brotlicffi using conda"
    Write-Host "[WhatIf] Environment path: $envPath"
    Write-Host "[WhatIf] Channel: conda-forge"
}

Write-Host "Taking ownership and setting permissions..."
if ($PSCmdlet.ShouldProcess($sitePackagesPath, "Fix permissions")) {
    & takeown /F "$sitePackagesPath" /R /D Y
    & icacls.exe "$sitePackagesPath" /reset /T /Q
    & icacls.exe "$sitePackagesPath" /grant:r "${user}:(OI)(CI)F" /T /Q
    & icacls.exe "$sitePackagesPath" /grant:r "BUILTIN\IIS_IUSRS:(OI)(CI)F" /T /Q
} else {
    Write-Host "[WhatIf] Would take ownership of: $sitePackagesPath"
    Write-Host "[WhatIf] Would reset permissions on: $sitePackagesPath"
    Write-Host "[WhatIf] Would grant full control to: $user"
    Write-Host "[WhatIf] Would grant full control to: BUILTIN\IIS_IUSRS"
}

Write-Host "Restarting IIS..."
if ($PSCmdlet.ShouldProcess("IIS", "Restart service")) {
    iisreset
} else {
    Write-Host "[WhatIf] Would restart IIS"
}

Write-Host "Permission fixes completed."
