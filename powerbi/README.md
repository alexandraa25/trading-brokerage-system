# Power BI — Brokerage Analytics

Acest director conține raportul analitic al aplicației de brokeraj. Power BI citește din `BrokerageDW`, nu direct din `BrokerageDB`. Toate valorile consolidate sunt raportate în EUR.

## Fișiere

- `BrokerageAnalytics.pbix` — raportul principal Power BI Desktop;
- `advanced-orders-page.md` — instrucțiuni pentru pagina ordinelor STOP și STOP-LIMIT;
- `operational-audit-page.md` — instrucțiuni pentru pagina auditului operațional.

## Pregătirea datelor

Înainte de reîmprospătarea raportului, rulează fluxul ETL zilnic sau manual: `etl/07_refresh_staging_from_oltp.sql`, `etl/11_refresh_audit_staging.sql`, încărcătoarele de dimensiuni și fapte din `warehouse/`, apoi `warehouse/views/01_create_powerbi_views.sql`.

Scriptul [Run-DailyDataPipeline.ps1](../automation/Run-DailyDataPipeline.ps1) automatizează aceste etape.

## Conectare în Power BI Desktop

1. Alege **Obținere date** → **SQL Server**;
2. setează instanța SQL Server și baza de date `BrokerageDW`;
3. alege modul **Import**;
4. încarcă sursele de mai jos;
5. aplică reîmprospătarea după fiecare rulare ETL.

## Surse importate

| Sursă | Utilizare |
|---|---|
| `dw.vwPowerBiPortfolioEvolution` | valoarea zilnică a portofoliului, poziții și numerar |
| `dw.vwPowerBiCashFlow` | depuneri, retrageri, conversii și comisioane |
| `dw.FactTrade` | execuții, volume și comisioane detaliate |
| `dw.vwPowerBiOrderLifecycle` | ordine standard, STOP, STOP-LIMIT, anulări și expirări |
| `dw.FactKyc` | verificări KYC și durate de soluționare |
| `dw.vwPowerBiOperationalAudit` | conectări, audit acces și activitate asupra ordinelor |
| `dw.DimDate` | calendar pentru `FactTrade` |
| `dw.DimCustomer` | analiză după client și stare client |
| `dw.DimInstrument` | analiză după instrument și piață |
| `dw.DimCurrency` | analiză în moneda originală |

## Model de date

Păstrează relațiile de tip stea, cu filtrare într-o singură direcție, din dimensiune către fapt:

```text
DimDate[DateKey]                    1 → * FactTrade[DateKey]
DimCustomer[CustomerKey]            1 → * FactTrade[CustomerKey]
DimInstrument[InstrumentKey]        1 → * FactTrade[InstrumentKey]
DimCustomer[CustomerKey]            1 → * FactKyc[CustomerKey]
```

Pentru pagina KYC, folosește direct `FactKyc[SubmittedAt]` pentru filtrul de dată. Nu activa relații suplimentare către `DimDate` atunci când Power BI semnalează trasee ambigue între `FactTrade`, `DimCustomer` și `FactKyc`.

Pentru evoluția lunară KYC, creează în `FactKyc`:

```DAX
Luna depunere sortare =
DATE ( YEAR ( FactKyc[SubmittedAt] ), MONTH ( FactKyc[SubmittedAt] ), 1 )

Luna depunere =
FORMAT ( FactKyc[Luna depunere sortare], "MMM yyyy" )
```

Sortează `Luna depunere` după `Luna depunere sortare` și folosește-o pe axa graficului KYC.

## Pagini ale raportului

1. **Prezentare generală** — indicatori principali, valoare portofoliu, flux net, volum, comisioane, clienți activi și stări ale ordinelor.
2. **Portofolii și numerar** — valoare investită, poziții, numerar, depuneri, retrageri, operațiuni valutare și detalierea tranzacțiilor de numerar.
3. **Trading și execuții** — volume pe instrument, cumpărări/vânzări, comisioane, execuții și stări ale ordinelor.
4. **Ordine avansate** — STOP și STOP-LIMIT, declanșări, expirări, cantități comandate/executate/anulate și ordine rămase.
5. **KYC și operațiuni** — stări KYC, timp de soluționare, documente, motive de respingere și clienți blocați.
6. **Audit operațional** — conectări, modificări de acces, estimări, anulări parțiale și activitatea asupra ordinelor.

## Măsuri DAX importante

```DAX
Volum tranzacționat EUR =
SUM ( FactTrade[TradeValueReporting] )

Comisioane EUR =
SUM ( FactTrade[CommissionReporting] )

Flux net EUR =
SUM ( vwPowerBiCashFlow[SumaEur] )

Valoare portofoliu zilnic EUR =
SUM ( vwPowerBiPortfolioEvolution[ValoareTotalaEur] )
```

Cardurile de portofoliu nu trebuie să adune toate snapshoturile zilnice. Pentru valoarea curentă din intervalul selectat, folosește:

```DAX
Valoare portofoliu la ultima dată EUR =
VAR UltimaData =
    MAXX (
        ALLSELECTED ( vwPowerBiPortfolioEvolution[Data] ),
        vwPowerBiPortfolioEvolution[Data]
    )
RETURN
    CALCULATE (
        [Valoare portofoliu zilnic EUR],
        vwPowerBiPortfolioEvolution[Data] = UltimaData
    )
```

Pentru cardurile „Valoare investită”, „Valoare poziții” și „Numerar”, se folosește aceeași formulă, înlocuind coloana de valoare din măsura zilnică.

În graficele pe instrument, pune `DimInstrument[Symbol]` pe axă, nu simbolul dintr-o vizualizare neconectată. Astfel, filtrul ajunge corect la `FactTrade`.

## Formatare

- formatează valorile consolidate ca **EUR**;
- folosește data directă, nu ierarhia automată `Year → Quarter → Month → Day`, pentru evoluția zilnică;
- depuneri: verde sau turcoaz; retrageri: roșu; anulări: portocaliu;
- stări: executat verde, în așteptare mov, respins roșu, expirat gri;
- pentru sume originale în monede diferite, dezactivează totalurile; totalul `SumaEur` rămâne valid.

## Lucru local și integrare în aplicație

Raportul poate fi creat, reîmprospătat și prezentat local în Power BI Desktop fără Power BI Service. Aceasta este varianta actuală recomandată pentru proiectul de portofoliu.

Pentru afișarea interactivă în tabul **Power BI** al aplicației, raportul trebuie publicat ulterior în Power BI Service cu un cont Microsoft de serviciu sau instituțional. URL-ul **Secure embed** se configurează în `web/brokerage-ui/src/app/core/config/powerbi.config.ts`. Conturile personale Gmail nu pot fi folosite pentru Power BI Service.

Nu folosi `Publish to web` pentru date reale: raportul devine public.
