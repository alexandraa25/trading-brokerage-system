# Power BI

Power BI consumă date din `BrokerageDW`, nu direct din `BrokerageDB`. EUR este valuta de raportare pentru indicatorii consolidați.

## Surse recomandate

Importă din schema `dw`:

- `vwPowerBiCashFlow` pentru depuneri, retrageri, conversii și comisioane;
- `vwPowerBiPortfolioEvolution` pentru evoluția zilnică a portofoliului;
- `vwPowerBiOrderLifecycle` pentru ordine, execuții și ordine avansate;
- `vwPowerBiOperationalAudit` pentru conectări, acțiuni administrative și activitatea asupra ordinelor;
- `FactKyc` pentru analiza timpului de soluționare KYC.

## Pagini recomandate

1. **Prezentare generală**: valoare portofoliu EUR, flux net, comisioane, clienți activi și KYC în așteptare.
2. **Portofoliu și numerar**: evoluție zilnică, structură pe monedă, depuneri, retrageri și conversii.
3. **Trading**: volume, execuții, comisioane, instrumente și stări de ordin.
4. **Ordine avansate**: STOP/STOP-LIMIT, rată de declanșare, timp până la declanșare, ordine neexecutate și anulări parțiale.
5. **KYC și operațiuni**: stări KYC, timp de soluționare, respingeri, clienți blocați și alerte de calitate a datelor.
6. **Audit operațional**: conectări, acțiuni de acces, estimări de ordin, anulări parțiale și activări STOP.

## Măsuri DAX de bază

```DAX
Volum tranzacționat EUR = SUM ( FactTrade[TradeValueReporting] )
Comisioane EUR = SUM ( FactTrade[CommissionReporting] )
Flux net EUR = SUM ( vwPowerBiCashFlow[SumaEur] )
Valoare portofoliu EUR = SUM ( vwPowerBiPortfolioEvolution[ValoareTotalaEur] )
Timp mediu soluționare (minute) = AVERAGE ( vwPowerBiOrderLifecycle[MinutePanaLaSolutionare] )
```

Folosește `TradeValue` și `CommissionAmount` numai împreună cu `DimCurrency`; acestea sunt în moneda originală. Pentru valori consolidate, folosește câmpurile de raportare EUR.

Ghidul complet pentru pagina de ordine avansate, cu măsuri, vizualuri și filtre, este în [advanced-orders-page.md](advanced-orders-page.md). Fișierul `.pbix` este păstrat local și nu este versionat în Git.
Ghidul pentru audit este în [operational-audit-page.md](operational-audit-page.md).
