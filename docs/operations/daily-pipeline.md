# Operațiunea zilnică a datelor

La 17:15, sarcina Windows `TradingBrokerage-Daily-Data-Pipeline` rulează
`automation/Run-DailyDataPipeline.ps1`.

Fluxul este:

```text
BCE → BrokerageDB → staging → BrokerageDW → Power BI
```

Jurnalele locale sunt în `automation/logs/`. Importurile BCE sunt înregistrate
și în tabelul `audit.ExchangeRateImportLog` din `BrokerageDB`.

Pentru un test local fără apelul BCE:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File automation\Run-DailyDataPipeline.ps1 -SkipEcbImport
```

În Power BI Desktop, reîmprospătează raportul după finalizarea fluxului. În
Power BI Service, configurează un gateway local și reîmprospătarea după 17:30.
