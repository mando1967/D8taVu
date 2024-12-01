# Import the IIS module
Import-Module WebAdministration

# Define paths and settings
$siteName = "Default Web Site"
$appName = "D8TAVu"
$virtualDirName = "share"
$physicalPath = "C:\Users\a-gon\OneDrive\Documents"

# Configure virtual directory settings
$vdirPath = "IIS:\Sites\$siteName\$appName\$virtualDirName"

# Ensure the virtual directory exists
if (Test-Path $vdirPath) {
    Write-Host "Configuring virtual directory: $virtualDirPath"
    
    # Set pass-through authentication
    Set-ItemProperty $vdirPath -Name "userName" -Value ""
    Set-ItemProperty $vdirPath -Name "password" -Value ""
    
    # Enable anonymous authentication
    Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/anonymousAuthentication" -Name "enabled" -Value "True" -PSPath $vdirPath
    
    # Set physical path credentials to pass-through
    Clear-WebConfiguration -Filter "/system.applicationHost/sites/site[@name='$siteName']/application[@path='/$appName']/virtualDirectory[@path='/$virtualDirName']/virtualDirectoryDefaults/@userName" -PSPath "MACHINE/WEBROOT/APPHOST"
    Clear-WebConfiguration -Filter "/system.applicationHost/sites/site[@name='$siteName']/application[@path='/$appName']/virtualDirectory[@path='/$virtualDirName']/virtualDirectoryDefaults/@password" -PSPath "MACHINE/WEBROOT/APPHOST"
    
    Write-Host "Virtual directory configuration updated successfully"
} else {
    Write-Host "Error: Virtual directory not found at $vdirPath"
    exit 1
}

# Get the application pool identity
$appPoolName = (Get-WebApplication "Default Web Site/D8TAVu").applicationPool
Write-Host "Application Pool: $appPoolName"

# Configure folder permissions for the app pool identity
$Acl = Get-Acl $physicalPath
$AppPoolSid = (Get-IISAppPool $appPoolName).ProcessModel.IdentityType
$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($AppPoolSid, "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
$Acl.SetAccessRule($AccessRule)
Set-Acl $physicalPath $Acl

Write-Host "Folder permissions updated for application pool identity"
Write-Host "Configuration complete!"
