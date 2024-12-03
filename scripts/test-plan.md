# D8TAVu Deployment Scripts Test Plan

## 1. Individual Script Testing

### Infrastructure Scripts
- [ ] `master_setup.ps1 -WhatIf`
  - Verify admin rights check
  - Check script sequence display
  - Validate simulated actions for each sub-script

- [ ] `master_setup_env.ps1 -WhatIf`
  - Verify admin rights check
  - Check environment setup sequence
  - Validate simulated actions for each sub-script

### IIS Configuration Scripts
- [ ] `1_create_app_pool.ps1 -WhatIf`
  - Check app pool creation simulation
  - Verify permission settings simulation
  - Validate identity configuration simulation

- [ ] `1_configure_virtual_directory.ps1 -WhatIf`
  - Check virtual directory creation simulation
  - Verify permission settings simulation
  - Validate URL configuration simulation

- [ ] `1_install_url_rewrite.ps1 -WhatIf`
  - Check download simulation
  - Verify installation simulation
  - Validate rule configuration simulation

### Environment Setup Scripts
- [ ] `1_set_env_variables.ps1 -WhatIf`
  - Check FastCGI variable configuration simulation
  - Verify temp directory creation simulation
  - Validate permission settings simulation

- [ ] `2_create_web_env.ps1 -WhatIf`
  - Check Python environment creation simulation
  - Verify package installation simulation
  - Validate configuration file creation simulation

### Permission Scripts
- [ ] `1_check_set_permissions.ps1 -WhatIf`
  - Check permission verification simulation
  - Verify permission modification simulation
  - Validate inheritance settings simulation

- [ ] `2_fix_permissions.ps1 -WhatIf`
  - Check conda package installation simulation
  - Verify permission reset simulation
  - Validate IIS reset simulation

- [ ] `2_grant_access.ps1 -WhatIf`
  - Check ACL modification simulation
  - Verify permission grant simulation
  - Validate inheritance settings simulation

- [ ] `2_set_permissions.ps1 -WhatIf`
  - Check read-only attribute removal simulation
  - Verify recursive permission setting simulation
  - Validate IIS user access simulation

### File Operations Scripts
- [ ] `2_copy_static_files.ps1 -WhatIf`
  - Check file copy simulation
  - Verify directory creation simulation
  - Validate permission setting simulation

### Service Scripts
- [ ] `3_restart_iis.ps1 -WhatIf`
  - Check IIS restart simulation
  - Verify service status check simulation

### Testing Scripts
- [ ] `test-harness.ps1 -WhatIf`
  - Check script analysis simulation
  - Verify configuration validation simulation
  - Validate command execution simulation

## 2. Integration Testing

### Full Deployment Sequence
- [ ] Run complete setup with `-WhatIf`
  ```powershell
  .\master_setup.ps1 -WhatIf
  .\master_setup_env.ps1 -WhatIf
  ```
  - Verify all steps are simulated in correct order
  - Check for proper error handling
  - Validate configuration consistency

### Batch File Integration
- [ ] Test batch file handling in WhatIf mode
  - Verify proper simulation messages
  - Check for potential execution blocks
  - Validate error handling

## 3. Error Handling

### Permission Errors
- [ ] Test without admin rights
  - Verify proper error messages
  - Check for clean exit
  - Validate no system changes

### Configuration Errors
- [ ] Test with missing configuration
  - Verify proper error detection
  - Check for helpful error messages
  - Validate no system changes

### Path Errors
- [ ] Test with invalid paths
  - Verify proper error detection
  - Check for helpful error messages
  - Validate no system changes

## 4. Logging Validation

### Log File Content
- [ ] Check log file creation
  - Verify proper log formatting
  - Check timestamp accuracy
  - Validate message clarity

### WhatIf Messages
- [ ] Verify WhatIf message format
  - Check consistency across scripts
  - Verify action descriptions
  - Validate parameter display

## 5. Security Testing

### Permission Verification
- [ ] Check permission simulations
  - Verify no actual permission changes
  - Check proper ACL display
  - Validate security context

### Credential Handling
- [ ] Test credential requirements
  - Verify proper privilege escalation
  - Check secure credential handling
  - Validate no credential leaks

## 6. Recovery Testing

### Interrupted Operations
- [ ] Test script interruption
  - Verify no partial changes
  - Check cleanup procedures
  - Validate state consistency

### Rollback Simulation
- [ ] Test rollback scenarios
  - Verify rollback simulation
  - Check state preservation
  - Validate cleanup procedures

## Expected Results

### Success Criteria
1. All scripts should show simulated actions without making changes
2. Error handling should prevent any system modifications
3. Logs should clearly indicate simulated vs actual actions
4. Configuration should be properly validated
5. Security contexts should be properly checked
6. Batch files should be safely handled

### Test Environment
- Windows Server with IIS
- PowerShell 5.0+
- Administrator access
- Clean IIS installation
- Python/Conda environment
