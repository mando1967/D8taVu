[CmdletBinding(SupportsShouldProcess=$true)]
param()

# Import configuration
$configPath = Join-Path $PSScriptRoot "config.ps1"
if (-not (Test-Path $configPath)) {
    Write-Host "Configuration file not found: $configPath" -ForegroundColor Red
    exit 1
}
. $configPath

# Function to validate script syntax
function Test-ScriptSyntax {
    param(
        [string]$ScriptPath
    )
    
    $errors = $null
    $tokens = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$tokens, [ref]$errors)
    
    if ($errors) {
        Write-Host "[X] Syntax errors found in $([System.IO.Path]::GetFileName($ScriptPath)):" -ForegroundColor Red
        foreach ($error in $errors) {
            Write-Host "   Line $($error.Extent.StartLineNumber): $($error.Message)" -ForegroundColor Red
        }
        return $false
    }
    
    Write-Host "[OK] No syntax errors found in $([System.IO.Path]::GetFileName($ScriptPath))" -ForegroundColor Green
    return $true
}

# Function to validate configuration usage
function Test-ConfigurationUsage {
    param(
        [string]$ScriptPath
    )
    
    $scriptContent = Get-Content $ScriptPath -Raw
    $configVariables = @(
        'APP_NAME',
        'APP_ROOT',
        'WEB_SITE_NAME',
        'IIS_USER',
        'CONDA_PATH',
        'REQUIRED_PERMISSIONS',
        'ABORT_ON_ERROR',
        'VIRTUAL_DIR_NAME',
        'USER_FILES_PATH'
    )
    
    $usedVariables = @()
    foreach ($var in $configVariables) {
        if ($scriptContent -match "\`$$var") {
            $usedVariables += $var
        }
    }
    
    Write-Host "`nConfiguration variables used in $([System.IO.Path]::GetFileName($ScriptPath)):" -ForegroundColor Cyan
    foreach ($var in $usedVariables) {
        Write-Host "   * $var = $((Get-Variable -Name $var -ErrorAction SilentlyContinue).Value)" -ForegroundColor Yellow
    }
}

# Function to simulate script execution
function Test-ScriptExecution {
    param(
        [string]$ScriptPath
    )
    
    Write-Host "`nSimulating execution of $([System.IO.Path]::GetFileName($ScriptPath)):" -ForegroundColor Cyan
    
    try {
        if ($PSCmdlet.ShouldProcess($ScriptPath, "Simulate script execution")) {
            # Parse the script without executing
            $scriptBlock = [scriptblock]::Create((Get-Content $ScriptPath -Raw))
            $ast = $scriptBlock.Ast
            
            # Find all command elements
            $commands = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true)
            
            foreach ($command in $commands) {
                $cmdName = $command.GetCommandName()
                if ($cmdName) {
                    Write-Host "   Would execute: $($command.Extent.Text)" -ForegroundColor DarkGray
                }
            }
        } else {
            Write-Host "[WhatIf] Would analyze script: $([System.IO.Path]::GetFileName($ScriptPath))" -ForegroundColor DarkGray
            Write-Host "[WhatIf] Would identify and list all command executions" -ForegroundColor DarkGray
        }
    }
    catch {
        Write-Host "[X] Error analyzing script: $_" -ForegroundColor Red
        return $false
    }
    
    return $true
}

# Get all PowerShell scripts in order
$scripts = Get-ChildItem -Path $PSScriptRoot -Filter "*.ps1" | 
    Where-Object { $_.Name -match '^\d+_' } |
    Sort-Object Name

Write-Host "[START] Starting script validation..." -ForegroundColor Cyan
Write-Host "Found $($scripts.Count) scripts to validate`n" -ForegroundColor Cyan

foreach ($script in $scripts) {
    Write-Host "===================================================" -ForegroundColor Blue
    Write-Host "Testing script: $($script.Name)" -ForegroundColor Blue
    Write-Host "===================================================" -ForegroundColor Blue
    
    # Test syntax
    $syntaxValid = Test-ScriptSyntax -ScriptPath $script.FullName
    if (-not $syntaxValid) { continue }
    
    # Test configuration usage
    Test-ConfigurationUsage -ScriptPath $script.FullName
    
    # Simulate execution
    Test-ScriptExecution -ScriptPath $script.FullName
    
    Write-Host ""
}

Write-Host "[DONE] Script validation complete!" -ForegroundColor Green
