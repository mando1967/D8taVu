# Create new environment directory if it doesn't exist
$envPath = "C:\inetpub\wwwroot\D8TAVu\env"
if (-not (Test-Path $envPath)) {
    New-Item -ItemType Directory -Path $envPath -Force
}

# Set permissions
$user = "IIS APPPOOL\D8TAVu"
$acl = Get-Acl $envPath
$permission = $user, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
$acl.SetAccessRule($accessRule)
Set-Acl -Path $envPath -AclObject $acl

Write-Host "Environment directory created and permissions set at: $envPath"
Write-Host "Next steps:"
Write-Host "1. Create a new Python virtual environment in this location:"
Write-Host "   python -m venv C:\inetpub\wwwroot\D8TAVu\env"
Write-Host "2. Activate the environment and install required packages:"
Write-Host "   C:\inetpub\wwwroot\D8TAVu\env\Scripts\activate"
Write-Host "   pip install flask pandas yfinance matplotlib"
Write-Host "3. Update web.config with the new Python path"
