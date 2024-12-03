# D8TAVu Deployment Scripts Dry-Run Guide

## Overview
The D8TAVu deployment scripts support a comprehensive dry-run mode using PowerShell's `-WhatIf` parameter. This feature allows you to preview all actions that would be taken during deployment without actually making any changes to your system.

## Usage

### Basic Usage
To run any script in dry-run mode, simply add the `-WhatIf` parameter:

```powershell
.\master_setup.ps1 -WhatIf
.\master_setup_env.ps1 -WhatIf
```

### Individual Script Usage
You can also run individual scripts with `-WhatIf`:

```powershell
.\1_create_app_pool.ps1 -WhatIf
.\2_create_web_env.ps1 -WhatIf
```

## Features

### What Gets Simulated
- IIS configuration changes
- File system operations
- Permission changes
- Environment variable settings
- Package installations
- Service restarts

### What Gets Logged
- Simulated actions with parameters
- Configuration validation
- Error conditions
- Security context checks

## Best Practices

### 1. Always Test First
Always run scripts with `-WhatIf` first to:
- Preview all changes
- Verify correct configuration
- Identify potential issues
- Understand the deployment sequence

### 2. Check Permissions
- Run as administrator when required
- Verify security context is correct
- Check for proper access rights

### 3. Review Logs
- Check log files for simulated actions
- Verify all expected steps are present
- Look for any warning messages

### 4. Validate Configuration
- Ensure all paths exist
- Verify environment variables
- Check IIS settings
- Validate Python/Conda setup

### 5. Handle Batch Files
- Note that .bat files have limited WhatIf support
- Check log messages for batch file execution
- Review batch file contents separately

## Common Scenarios

### 1. Full Deployment Preview
```powershell
# Preview full deployment
.\master_setup.ps1 -WhatIf
.\master_setup_env.ps1 -WhatIf
```

### 2. Environment Setup Preview
```powershell
# Preview environment creation
.\2_create_web_env.ps1 -WhatIf
.\1_set_env_variables.ps1 -WhatIf
```

### 3. Permission Changes Preview
```powershell
# Preview permission changes
.\2_set_permissions.ps1 -WhatIf
.\2_grant_access.ps1 -WhatIf
```

## Troubleshooting

### Common Issues

1. **Administrator Rights**
   - Error: "This script must be run as Administrator"
   - Solution: Run PowerShell as Administrator

2. **Missing Configuration**
   - Error: "Configuration file not found"
   - Solution: Ensure config.ps1 exists and is properly set up

3. **Invalid Paths**
   - Error: "Directory not found"
   - Solution: Verify all paths in config.ps1

4. **Permission Errors**
   - Error: "Access denied"
   - Solution: Check user permissions and security context

### Log Messages

Understanding log message types:
- `[WhatIf]` - Simulated action
- `[Info]` - Informational message
- `[Warning]` - Non-critical issue
- `[Error]` - Critical issue

## Security Considerations

### 1. Privilege Escalation
- Scripts requiring admin rights will check privileges
- WhatIf mode still requires appropriate permissions

### 2. Permission Changes
- Permission changes are simulated
- No actual modifications in WhatIf mode
- Security context is preserved

### 3. Credential Handling
- Credentials are never logged
- Security-sensitive operations are noted
- Access tokens are properly managed

## Limitations

### 1. Batch Files
- Limited WhatIf support for .bat files
- Actions are logged but not fully simulated

### 2. External Tools
- Some external tools may not support WhatIf
- Actions are logged but may require manual review

### 3. Dynamic Operations
- Some operations may depend on runtime state
- Actual execution may vary from simulation

## Support

### Getting Help
- Review script comments for details
- Check log files for error messages
- Use test-harness.ps1 for validation
- Contact system administrator for assistance

### Reporting Issues
- Capture full log output
- Note any error messages
- Document expected vs actual behavior
- Include system configuration details

## Conclusion
Using dry-run mode is an essential practice for safe and predictable deployments. Always preview changes before applying them to your system, and maintain proper documentation of your deployment process.
