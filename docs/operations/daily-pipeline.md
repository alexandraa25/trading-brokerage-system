# Operațiunea zilnică a datelor

Sarcina Windows `TradingBrokerage-Daily-Data-Pipeline` rulează la 17:15, ora Bucureștiului, fișierul `automation/Run-DailyDataPipeline.ps1`.

```text
BCE + cotații → BrokerageDB → staging → BrokerageDW → Power BI
```

## Ce face rularea

1. importă cursurile BCE disponibile și păstrează data oficială a cursului;
2. actualizează cotațiile demonstrative sau sursa configurată pentru instrumente;
3. activează ordinele STOP al căror prag a fost atins și marchează motivele pentru STOP-LIMIT neexecutabile;
4. copiază schimbările în staging;
5. încarcă dimensiunile și faptele din `BrokerageDW`;
6. scrie rezultate și erori în jurnale;
7. permite reîmprospătarea raportului Power BI după finalizare.

Jurnalele locale sunt în `automation/logs/`. Importurile BCE sunt înregistrate și în `audit.ExchangeRateImportLog`. Administratorul este alertat dacă lipsesc cursuri BCE sau cotații recente.

## Rulare manuală

Pentru un test local fără apel BCE:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File automation\Run-DailyDataPipeline.ps1 -SkipEcbImport
```

Pentru un flux complet, rulează scriptul fără parametrul `-SkipEcbImport`.

## Power BI

În Power BI Desktop, apasă **Refresh** după finalizarea fluxului. Pentru Power BI Service sunt necesare publicarea raportului, un cont work/school și, pentru SQL Server local, un gateway configurat. Reîmprospătarea trebuie planificată după terminarea rulării zilnice.

## Docker

Când aplicația rulează în Docker, baza de date păstrează datele în volumul `sql-data`. Pentru oprire folosește `docker-compose down`; nu folosi `docker-compose down -v` dacă vrei să păstrezi datele din container.
