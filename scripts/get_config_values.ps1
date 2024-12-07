# This script reads values from config.ps1 and outputs them in a format
# that can be parsed by batch files
param(
    [Parameter(Mandatory=$true)]
    [string[]]$ConfigNames
)

# Import configuration
$configPath = Join-Path $PSScriptRoot "config.ps1"
if (-not (Test-Path $configPath)) {
    Write-Error "Configuration file not found: $configPath"
    exit 1
}
. $configPath

# Output requested values separated by spaces
$values = @()
foreach ($name in $ConfigNames) {
    $value = Get-Variable -Name $name -ValueOnly -ErrorAction SilentlyContinue
    if ($null -eq $value) {
        Write-Error "Configuration value not found: $name"
        exit 1
    }
    $values += $value
}

# Output values space-separated (for batch file parsing)
$values -join " "
