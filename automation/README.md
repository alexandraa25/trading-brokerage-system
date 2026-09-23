# Automatizarea fluxului zilnic

`Run-DailyDataPipeline.ps1` execută, în această ordine:

1. importul cursurilor oficiale BCE;
2. actualizarea cotațiilor simulate și capturarea valorii zilnice a portofoliilor;
3. reconstruirea staging-ului din `BrokerageDB`;
4. încărcarea dimensiunilor și a faptelor în `BrokerageDW`;
5. scrierea unui jurnal în `automation/logs/`.

Poți testa local fluxul fără apelul BCE:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File automation\Run-DailyDataPipeline.ps1 -SkipEcbImport
```

Pentru rularea zilnică la 17:15:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File automation\Install-DailyEcbRateTask.ps1
```

În Power BI Desktop, apasă **Reîmprospătare** după terminarea fluxului. Pentru
Power BI Service, publică raportul și configurează un gateway local plus o
reîmprospătare programată după ora 17:30; serviciul va interoga aceleași
vizualizări din `BrokerageDW`.
