# Trading Brokerage System

Aplicație de portofoliu pentru administrarea unei platforme de brokeraj.
Acoperă fluxul complet de lucru pentru client, broker și administrator, cu
cursuri BCE, depozit de date și raportare Power BI. EUR este moneda principală
de raportare.

## Funcționalități

### Client

- înregistrare, autentificare și stare KYC;
- conturi de numerar în mai multe monede;
- depuneri, retrageri și conversii la curs BCE;
- poziții, instrumente, ordine și istoric;
- valoare portofoliu, profit/pierdere și evoluție zilnică;
- notificări persistente.

### Broker

- ordine active cu filtre, paginare și alerte;
- execuții complete sau parțiale cu validări;
- respingere cu motiv obligatoriu;
- istoric, export CSV și notificări broker.

### Administrator

- verificare KYC, clienți, conturi și utilizatori;
- suspendare/reactivare cu motiv obligatoriu;
- indicatori operaționali, alerte și jurnale de audit;
- export CSV pentru date administrative.

## Arhitectură

```text
Angular → ASP.NET Core API → BrokerageDB → staging → BrokerageDW → Power BI
                                  ▲
                                  └──────────── BCE
```

- `BrokerageDB` este baza operațională.
- `staging` pregătește datele pentru analiză.
- `BrokerageDW` este depozitul dimensional folosit de Power BI.
- Automatizarea zilnică importă cursuri BCE, actualizează staging-ul și
  încarcă depozitul.

## Tehnologii

- SQL Server și T-SQL;
- ASP.NET Core 10, Entity Framework Core și JWT;
- Angular 20 și TypeScript;
- PowerShell, Windows Task Scheduler și Power BI.

## Structură

```text
trading-brokerage-system/
├── api/          # API ASP.NET Core
├── web/          # interfața Angular
├── database/     # baza operațională BrokerageDB
├── etl/          # staging și transformări
├── warehouse/    # depozitul BrokerageDW
├── automation/   # flux zilnic BCE → staging → DW
├── tests/        # validări SQL automate
├── docs/         # arhitectură, operațiuni și ghiduri
└── powerbi/      # ghid și capturi ale raportului
```

Ghiduri specifice: [API](api/Brokerage/README.md), [baza operațională](database/README.md),
[ETL](etl/README.md), [depozitul de date](warehouse/README.md),
[automatizarea](automation/README.md) și [Power BI](powerbi/README.md).

## Pornire locală

### Baza de date

Rulează scripturile în ordinea din [database/README.md](database/README.md).
Pentru date demonstrative extinse poți rula:

```text
database/demo/01_seed_diverse_demo_data.sql
```

### API

În `api/Brokerage/Brokerage`:

```powershell
dotnet run
```

Swagger: `https://localhost:7103/swagger`.

Cheia JWT se configurează local prin User Secrets sub `Jwt:Key` și nu se
salvează în Git.

### Interfață

În `web/brokerage-ui`:

```powershell
npm install
npm start
```

Interfața: `http://localhost:4200`.

## Conturi demonstrative

| Rol | Email | Parolă |
| --- | --- | --- |
| Client | `customer.demo@brokerage.local` | `DemoCustomer!2026` |
| Broker | `broker.demo@brokerage.local` | `DemoBroker!2026` |
| Administrator | `admin.demo@brokerage.local` | `DemoAdmin!2026` |

## Automatizare zilnică

Sarcina Windows `TradingBrokerage-Daily-Data-Pipeline` rulează la 17:15:

```text
Import BCE → cotații și snapshoturi → staging → BrokerageDW
```

Instalare sau actualizare:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File automation\Install-DailyEcbRateTask.ps1
```

Test local fără apel BCE:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File automation\Run-DailyDataPipeline.ps1 -SkipEcbImport
```

Mai multe detalii: [operațiunea zilnică](docs/operations/daily-pipeline.md).

## Depozit de date și Power BI

`BrokerageDW` include dimensiuni pentru dată, client, cont, instrument și
monedă, plus fapte pentru execuții, cursuri valutare, numerar, portofolii,
ordine și KYC.

Importă în Power BI vizualizările:

- `dw.vwPowerBiCashFlow`;
- `dw.vwPowerBiPortfolioEvolution`;
- `dw.vwPowerBiOrderLifecycle`.

Pentru Power BI Service este necesar un gateway local și o reîmprospătare după
17:30.

## Testare

Scripturile SQL din `tests/` verifică fluxurile importante, integritatea,
conversiile, auditul și depozitul. După o încărcare completă a depozitului,
rulează:

```text
tests/14_data_warehouse_validation.sql
tests/17_currency_dw_validation.sql
tests/19_cash_transaction_dw_validation.sql
tests/20_portfolio_snapshot_dw_validation.sql
tests/21_order_lifecycle_dw_validation.sql
tests/22_kyc_dw_validation.sql
tests/23_admin_analytics_validation.sql
```

Testele automate ale interfeței se rulează în web/brokerage-ui:

``powershell
npm run test:ci
`` 

Comanda folosește Chrome headless și verifică filtrele administrative, ferestrele modale și graficul analitic. Pentru verificarea manuală, folosește [checklistul manual](docs/testing/manual-checklist.md).

## Notă

Proiectul este demonstrativ: cotațiile instrumentelor sunt simulate, iar
cursurile valutare sunt păstrate istoric pentru ca rapoartele și tranzacțiile
vechi să rămână corecte.

Memoria de continuitate a proiectului este în [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md).

### Teste automate API

Din `api/Brokerage`, rulează:

```powershell
dotnet test Brokerage.Api.Tests/Brokerage.Api.Tests.csproj
```

Suita pornește API-ul cu SQLite temporar și verifică autentificarea, rolurile, accesul interzis, izolarea conturilor, validarea ordinelor, brokerul și administratorul. Nu modifică `BrokerageDB`.