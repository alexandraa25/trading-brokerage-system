[CmdletBinding()]
param(
    [string]$ServerInstance = 'localhost',
    [string]$Database = 'BrokerageDB',
    [int]$DaysBack = 10,
    [switch]$FullHistory,
    [datetime]$EndDate = (Get-Date).Date
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$end = $EndDate.Date
$start = if ($FullHistory) { [datetime]'2020-01-01' } else { $end.AddDays(-$DaysBack) }
$currencies = @('USD', 'GBP', 'RON', 'CAD', 'JPY')
$series = [string]::Join('+', $currencies)
$uri = 'https://data-api.ecb.europa.eu/service/data/EXR/D.{0}.EUR.SP00.A?startPeriod={1}&endPeriod={2}&format=csvdata' -f `
    $series, $start.ToString('yyyy-MM-dd'), $end.ToString('yyyy-MM-dd')

$connectionString = 'Server={0};Database={1};Integrated Security=True;Encrypt=True;TrustServerCertificate=True;' -f `
    $ServerInstance, $Database
$connection = New-Object System.Data.SqlClient.SqlConnection $connectionString
$importRunId = $null

function New-SqlCommand {
    param([string]$CommandText)
    $command = $connection.CreateCommand()
    $command.CommandText = $CommandText
    $command.CommandTimeout = 120
    return $command
}

try {
    $connection.Open()

    $startCommand = New-SqlCommand @'
INSERT INTO audit.ExchangeRateImportLog
    (SourceSystem, DateFrom, DateTo, Status)
VALUES
    ('ECB_REFERENCE', @DateFrom, @DateTo, 'Running');
SELECT CAST(SCOPE_IDENTITY() AS BIGINT);
'@
    [void]$startCommand.Parameters.Add('@DateFrom', [Data.SqlDbType]::Date)
    [void]$startCommand.Parameters.Add('@DateTo', [Data.SqlDbType]::Date)
    $startCommand.Parameters['@DateFrom'].Value = $start
    $startCommand.Parameters['@DateTo'].Value = $end
    $importRunId = [long]$startCommand.ExecuteScalar()

    $response = Invoke-WebRequest -UseBasicParsing -Uri $uri -Headers @{ Accept = 'text/csv' }
    $sourceRows = @($response.Content | ConvertFrom-Csv | Where-Object {
        $_.FREQ -eq 'D' -and
        $_.CURRENCY_DENOM -eq 'EUR' -and
        $currencies -contains $_.CURRENCY -and
        $_.OBS_VALUE
    })

    if ($sourceRows.Count -eq 0) {
        throw 'BCE nu a returnat niciun curs pentru intervalul solicitat.'
    }

    $now = Get-Date
    $isWorkingDay = $end.DayOfWeek -notin @(
        [DayOfWeek]::Saturday,
        [DayOfWeek]::Sunday
    )
    $hasCurrentDate = $null -ne ($sourceRows | Where-Object {
        $_.TIME_PERIOD -eq $end.ToString('yyyy-MM-dd')
    } | Select-Object -First 1)

    # După ora programată, absența cursului din ziua curentă produce o eroare.
    # Windows Task Scheduler va reîncerca automat de trei ori.
    if (-not $FullHistory -and
        $end -eq $now.Date -and
        $now.TimeOfDay -ge ([TimeSpan]::Parse('17:15')) -and
        $isWorkingDay -and
        -not $hasCurrentDate) {
        throw "Cursul BCE pentru $($end.ToString('yyyy-MM-dd')) nu a fost încă publicat."
    }

    $table = New-Object System.Data.DataTable
    [void]$table.Columns.Add('SourceCurrency', [string])
    [void]$table.Columns.Add('TargetCurrency', [string])
    [void]$table.Columns.Add('RateDate', [datetime])
    [void]$table.Columns.Add('MidRate', [decimal])

    foreach ($sourceRow in $sourceRows) {
        $ecbQuote = [decimal]::Parse(
            $sourceRow.OBS_VALUE,
            [Globalization.CultureInfo]::InvariantCulture
        )
        if ($ecbQuote -le 0) {
            throw "Curs BCE invalid pentru $($sourceRow.CURRENCY) la $($sourceRow.TIME_PERIOD)."
        }

        # BCE publică 1 EUR = X valută; modelul folosește 1 valută = X EUR.
        $midRate = [decimal]::Round((1 / $ecbQuote), 10, [MidpointRounding]::AwayFromZero)
        $row = $table.NewRow()
        $row.SourceCurrency = $sourceRow.CURRENCY
        $row.TargetCurrency = 'EUR'
        $row.RateDate = [datetime]::ParseExact(
            $sourceRow.TIME_PERIOD,
            'yyyy-MM-dd',
            [Globalization.CultureInfo]::InvariantCulture
        )
        $row.MidRate = $midRate
        $table.Rows.Add($row)
    }

    $transaction = $connection.BeginTransaction()
    try {
        $createTemp = New-SqlCommand @'
CREATE TABLE #EcbRates
(
    SourceCurrency CHAR(3) NOT NULL,
    TargetCurrency CHAR(3) NOT NULL,
    RateDate DATE NOT NULL,
    MidRate DECIMAL(19,10) NOT NULL
);
'@
        $createTemp.Transaction = $transaction
        [void]$createTemp.ExecuteNonQuery()

        $bulkCopy = New-Object System.Data.SqlClient.SqlBulkCopy(
            $connection,
            [System.Data.SqlClient.SqlBulkCopyOptions]::CheckConstraints,
            $transaction
        )
        $bulkCopy.DestinationTableName = '#EcbRates'
        $bulkCopy.BulkCopyTimeout = 120
        foreach ($column in $table.Columns) {
            [void]$bulkCopy.ColumnMappings.Add($column.ColumnName, $column.ColumnName)
        }
        $bulkCopy.WriteToServer($table)
        $bulkCopy.Close()

        $mergeCommand = New-SqlCommand @'
DECLARE @Changes TABLE (ActionName NVARCHAR(10) NOT NULL);

MERGE core.ExchangeRate AS target
USING #EcbRates AS source
ON target.SourceCurrency = source.SourceCurrency
AND target.TargetCurrency = source.TargetCurrency
AND target.RateDate = source.RateDate
WHEN MATCHED AND
(
       target.MidRate <> source.MidRate
    OR target.BuyRate <> source.MidRate
    OR target.SellRate <> source.MidRate
    OR target.SourceSystem <> 'ECB_REFERENCE'
)
THEN UPDATE SET
    MidRate = source.MidRate,
    BuyRate = source.MidRate,
    SellRate = source.MidRate,
    SourceSystem = 'ECB_REFERENCE'
WHEN NOT MATCHED THEN
    INSERT
    (
        SourceCurrency, TargetCurrency, RateDate,
        MidRate, BuyRate, SellRate, SourceSystem
    )
    VALUES
    (
        source.SourceCurrency, source.TargetCurrency, source.RateDate,
        source.MidRate, source.MidRate, source.MidRate, 'ECB_REFERENCE'
    )
OUTPUT $action INTO @Changes;

SELECT
    SUM(CASE WHEN ActionName = 'INSERT' THEN 1 ELSE 0 END) AS RowsInserted,
    SUM(CASE WHEN ActionName = 'UPDATE' THEN 1 ELSE 0 END) AS RowsUpdated
FROM @Changes;
'@
        $mergeCommand.Transaction = $transaction
        $reader = $mergeCommand.ExecuteReader()
        $rowsInserted = 0
        $rowsUpdated = 0
        if ($reader.Read()) {
            if (-not $reader.IsDBNull(0)) { $rowsInserted = $reader.GetInt32(0) }
            if (-not $reader.IsDBNull(1)) { $rowsUpdated = $reader.GetInt32(1) }
        }
        $reader.Close()

        if ($FullHistory) {
            $replaceDemo = New-SqlCommand @'
DELETE FROM core.ExchangeRate
WHERE SourceSystem = 'DEMO_EUR_DAILY';

UPDATE execution_row
SET
    ExchangeRateToReporting = official_rate.MidRate,
    ExchangeRateDate = official_rate.RateDate,
    ExchangeRateSource = 'ECB_REFERENCE',
    TradeValueReporting = ROUND
    (
        execution_row.ExecutedQuantity * execution_row.ExecutionPrice
        * official_rate.MidRate,
        4
    ),
    CommissionReporting = ROUND(ISNULL(commission.TotalCommission, 0) * official_rate.MidRate, 4)
FROM trading.Execution execution_row
INNER JOIN trading.[Order] order_row ON order_row.OrderId = execution_row.OrderId
INNER JOIN trading.Instrument instrument ON instrument.InstrumentId = order_row.InstrumentId
CROSS APPLY
(
    SELECT TOP (1) rate_row.RateDate, rate_row.MidRate
    FROM core.ExchangeRate rate_row
    WHERE rate_row.SourceCurrency = instrument.Currency
      AND rate_row.TargetCurrency = 'EUR'
      AND rate_row.SourceSystem = 'ECB_REFERENCE'
      AND rate_row.RateDate <= CAST(execution_row.ExecutedAt AS DATE)
    ORDER BY rate_row.RateDate DESC
) official_rate
OUTER APPLY
(
    SELECT SUM(Amount) AS TotalCommission
    FROM trading.Commission
    WHERE ExecutionId = execution_row.ExecutionId
) commission
WHERE instrument.Currency <> 'EUR'
  AND execution_row.ExchangeRateSource <> 'ECB_REFERENCE';

UPDATE trading.Execution
SET
    ExchangeRateToReporting = 1,
    ExchangeRateDate = CAST(ExecutedAt AS DATE),
    ExchangeRateSource = 'IDENTITY',
    TradeValueReporting = ROUND(ExecutedQuantity * ExecutionPrice, 4),
    CommissionReporting = ISNULL
    (
        (SELECT SUM(Amount) FROM trading.Commission
         WHERE ExecutionId = trading.Execution.ExecutionId),
        0
    )
WHERE TradeCurrency = 'EUR';
'@
            $replaceDemo.Transaction = $transaction
            [void]$replaceDemo.ExecuteNonQuery()
        }

        $transaction.Commit()

        # După ce cursurile BCE sunt actualizate, salvează valoarea zilnică
        # a fiecărui portofoliu pentru graficul istoric în EUR.
        $snapshotCommand = New-SqlCommand @'
EXEC trading.usp_RefreshSimulatedMarketQuotes;
EXEC reporting.usp_CapturePortfolioDailySnapshot;
'@
        [void]$snapshotCommand.ExecuteNonQuery()

        $finishCommand = New-SqlCommand @'
UPDATE audit.ExchangeRateImportLog
SET CompletedAt = SYSUTCDATETIME(),
    Status = 'Succeeded',
    RowsReceived = @RowsReceived,
    RowsInserted = @RowsInserted,
    RowsUpdated = @RowsUpdated
WHERE ImportRunId = @ImportRunId;
'@
        [void]$finishCommand.Parameters.Add('@RowsReceived', [Data.SqlDbType]::Int)
        [void]$finishCommand.Parameters.Add('@RowsInserted', [Data.SqlDbType]::Int)
        [void]$finishCommand.Parameters.Add('@RowsUpdated', [Data.SqlDbType]::Int)
        [void]$finishCommand.Parameters.Add('@ImportRunId', [Data.SqlDbType]::BigInt)
        $finishCommand.Parameters['@RowsReceived'].Value = $table.Rows.Count
        $finishCommand.Parameters['@RowsInserted'].Value = $rowsInserted
        $finishCommand.Parameters['@RowsUpdated'].Value = $rowsUpdated
        $finishCommand.Parameters['@ImportRunId'].Value = $importRunId
        [void]$finishCommand.ExecuteNonQuery()

        Write-Output ("Import BCE reușit: {0} cursuri primite, {1} inserate, {2} actualizate." -f `
            $table.Rows.Count, $rowsInserted, $rowsUpdated)
    }
    catch {
        $transaction.Rollback()
        throw
    }
}
catch {
    if ($connection.State -eq [Data.ConnectionState]::Open -and $importRunId) {
        $failureCommand = New-SqlCommand @'
UPDATE audit.ExchangeRateImportLog
SET CompletedAt = SYSUTCDATETIME(),
    Status = 'Failed',
    ErrorMessage = LEFT(@ErrorMessage, 2000)
WHERE ImportRunId = @ImportRunId;
'@
        [void]$failureCommand.Parameters.Add('@ErrorMessage', [Data.SqlDbType]::NVarChar, 2000)
        [void]$failureCommand.Parameters.Add('@ImportRunId', [Data.SqlDbType]::BigInt)
        $failureCommand.Parameters['@ErrorMessage'].Value = $_.Exception.Message
        $failureCommand.Parameters['@ImportRunId'].Value = $importRunId
        [void]$failureCommand.ExecuteNonQuery()
    }
    throw
}
finally {
    if ($connection.State -ne [Data.ConnectionState]::Closed) {
        $connection.Close()
    }
    $connection.Dispose()
}
