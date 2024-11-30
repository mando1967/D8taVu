$paths = @(
    "C:\Users\a-gon\anaconda3\envs\D8TAVu",
    "C:\Users\a-gon\anaconda3\envs\D8TAVu\Lib",
    "C:\Users\a-gon\anaconda3\envs\D8TAVu\Lib\site-packages"
)
$user = "IIS APPPOOL\D8TAVu"

foreach ($path in $paths) {
    Write-Host "Setting permissions for $path..."
    $acl = Get-Acl $path
    $permission = $user, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
    $acl.SetAccessRule($accessRule)
    Set-Acl -Path $path -AclObject $acl
    
    # Apply to all subdirectories and files
    Get-ChildItem -Path $path -Recurse -Force | ForEach-Object {
        $itemAcl = Get-Acl $_.FullName
        $itemAcl.SetAccessRule($accessRule)
        Set-Acl -Path $_.FullName -AclObject $itemAcl
    }
}

Write-Host "Permissions have been set successfully!"
