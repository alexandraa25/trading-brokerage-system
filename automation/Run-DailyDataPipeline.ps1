[CmdletBinding()]
param(
    [string]$ServerInstance = 'localhost',
    [string]$OperationalDatabase = 'BrokerageDB',
    [string]$WarehouseDatabase = 'BrokerageDW',
    [int]$DaysBack = 10,
    [switch]$SkipEcbImport
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$logDirectory = Join-Path $PSScriptRoot 'logs'
New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
$logPath = Join-Path $logDirectory ('daily-pipeline-{0}.log' -f (Get-Date -Format 'yyyyMMdd-HHmmss'))

function Write-PipelineLog {
    param([string]$Message)
    $line = '{0:u} {1}' -f (Get-Date), $Message
    $line | Tee-Object -FilePath $logPath -Append
}

function Invoke-SqlFile {
    param([string]$Database, [string]$RelativePath)
    $filePath = Join-Path $projectRoot $RelativePath
    if (-not (Test-Path -LiteralPath $filePath)) { throw "Lipsește scriptul SQL: $filePath" }
    Write-PipelineLog "Rulez $RelativePath"
    & sqlcmd -S $ServerInstance -E -b -d $Database -i $filePath | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Scriptul a eșuat: $RelativePath" }
}

try {
    Write-PipelineLog 'Pornire flux zilnic de date.'

    if (-not $SkipEcbImport) {
        $importScript = Join-Path $PSScriptRoot 'Import-EcbExchangeRates.ps1'
        Write-PipelineLog 'Import cursuri BCE și captură zilnică a portofoliilor.'
        & $importScript -ServerInstance $ServerInstance -Database $OperationalDatabase -DaysBack $DaysBack
        if ($LASTEXITCODE -ne 0) { throw 'Importul BCE a eșuat.' }
    }

    Invoke-SqlFile -Database $OperationalDatabase -RelativePath 'etl/07_refresh_staging_from_oltp.sql'
    Invoke-SqlFile -Database $OperationalDatabase -RelativePath 'etl/11_refresh_audit_staging.sql'
    Invoke-SqlFile -Database $WarehouseDatabase -RelativePath 'warehouse/04_load_dimensions.sql'
    Invoke-SqlFile -Database $WarehouseDatabase -RelativePath 'warehouse/05_load_fact_trade.sql'
    Invoke-SqlFile -Database $WarehouseDatabase -RelativePath 'warehouse/09_load_fact_cash_transaction.sql'
    Invoke-SqlFile -Database $WarehouseDatabase -RelativePath 'warehouse/11_load_fact_portfolio_daily_snapshot.sql'
    Invoke-SqlFile -Database $WarehouseDatabase -RelativePath 'warehouse/13_load_fact_order_lifecycle.sql'
    Invoke-SqlFile -Database $WarehouseDatabase -RelativePath 'warehouse/16_load_fact_kyc.sql'
    Invoke-SqlFile -Database $WarehouseDatabase -RelativePath 'warehouse/19_operational_audit_analytics.sql'

    Write-PipelineLog 'Fluxul zilnic de date s-a finalizat cu succes.'
}
catch {
    Write-PipelineLog ("Flux eșuat: {0}" -f $_.Exception.Message)
    throw
}
