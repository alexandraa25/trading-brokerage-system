[CmdletBinding()]
param(
    [string]$ServerInstance = 'localhost',
    [string]$Database = 'BrokerageDB',
    [string]$TaskName = 'TradingBrokerage-ECB-Daily-Rates',
    [string]$DailyTime = '17:15'
)

$ErrorActionPreference = 'Stop'
$importScript = Join-Path $PSScriptRoot 'Import-EcbExchangeRates.ps1'

if (-not (Test-Path -LiteralPath $importScript)) {
    throw "Nu a fost găsit importatorul BCE: $importScript"
}

$arguments = '-NoProfile -ExecutionPolicy Bypass -File "{0}" -ServerInstance "{1}" -Database "{2}" -DaysBack 10' -f `
    $importScript, $ServerInstance, $Database
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $arguments
$trigger = New-ScheduledTaskTrigger -Daily -At $DailyTime
$settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 15) `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 10)

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Description 'Importă zilnic cursurile oficiale BCE în BrokerageDB.' `
    -Force | Out-Null

Write-Output "Sarcina '$TaskName' a fost configurată zilnic la ora $DailyTime."
