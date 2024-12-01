# Get the application pool identity
$appPoolName = "D8TAVu"  # or your specific app pool name
$appPoolSid = "IIS AppPool\$appPoolName"

# Set the path to grant access to
$folderPath = "C:\Users\a-gon\OneDrive\Documents"

# Get current ACL
$acl = Get-Acl $folderPath

# Create new rule for app pool
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $appPoolSid,
    "ReadAndExecute",
    "ContainerInherit,ObjectInherit",
    "None",
    "Allow"
)

# Add the rule to the ACL
$acl.AddAccessRule($rule)

# Apply the new ACL
Set-Acl -Path $folderPath -AclObject $acl

Write-Host "Permissions granted to $appPoolSid on $folderPath"
