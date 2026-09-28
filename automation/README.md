# Automatizarea fluxului zilnic

`Run-DailyDataPipeline.ps1` actualizează datele necesare aplicației și raportării.

## Flux

1. importă cursurile oficiale BCE;
2. reîmprospătează cotațiile simulate și snapshoturile zilnice de portofoliu;
3. reconstruiește staging-ul din `BrokerageDB`, inclusiv jurnalul operațional;
4. încarcă dimensiunile și faptele în `BrokerageDW`, inclusiv auditul operațional;
5. scrie rezultatul în `automation/logs/`.

Cotațiile și cursurile actualizate permit estimări, ordine STOP și monitorizare administrativă bazate pe datele zilei. Administratorul este avertizat în aplicație când ultimele date BCE sau cotații sunt prea vechi.

## Rulare

Test local fără apel BCE:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File automation\Run-DailyDataPipeline.ps1 -SkipEcbImport
```

Instalarea sarcinii zilnice la 17:15:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File automation\Install-DailyEcbRateTask.ps1
```

După finalizare, reîmprospătează raportul în Power BI Desktop. În Power BI Service configurează un gateway local și o reîmprospătare programată după 17:30.
