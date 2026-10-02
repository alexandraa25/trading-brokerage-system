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

## Programare, oprire și verificare

Automatizarea nu pornește aplicația Docker și nu ține browserul deschis. Ea rulează numai scriptul de import BCE și ETL, la ora programată.

### Crearea sau actualizarea unei singure sarcini zilnice

Din rădăcina proiectului, rulează în PowerShell:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File automation\Install-DailyEcbRateTask.ps1
```

Această comandă creează sau actualizează sarcina Windows:

```text
TradingBrokerage-Daily-Data-Pipeline
```

Ora implicită este 17:15. Pentru altă oră, de exemplu 18:00:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File automation\Install-DailyEcbRateTask.ps1 -DailyTime "18:00"
```

### Oprirea actualizării automate

În **Task Scheduler**, caută `TradingBrokerage-Daily-Data-Pipeline`, selecteaz-o și apasă **Disable** în panoul din dreapta. Sarcina rămâne salvată, dar nu va mai rula.

Alternativ, în PowerShell:

```powershell
Disable-ScheduledTask -TaskName "TradingBrokerage-Daily-Data-Pipeline"
```

Pentru reactivare:

```powershell
Enable-ScheduledTask -TaskName "TradingBrokerage-Daily-Data-Pipeline"
```

### Evitarea rulărilor duplicate

Păstrează o singură sarcină pentru acest proiect. Dacă în Task Scheduler apar două sarcini `TradingBrok...` la aceeași oră, deschide **Properties → Actions** pentru fiecare. Oprește-o pe cea care pornește același fișier `automation\Run-DailyDataPipeline.ps1` ca sarcina păstrată.

Nu șterge o sarcină dacă nu ești sigură ce face; **Disable** este reversibil.

### Rulare și jurnal manual

Poți rula fluxul oricând, fără să aștepți ora programată:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File automation\Run-DailyDataPipeline.ps1
```

Jurnalele fiecărei rulări sunt în `automation/logs/`. După o rulare reușită, reîmprospătează raportul în Power BI Desktop.
