# Power BI

## Raportarea valutară

EUR este valuta principală de afișare. Pentru indicatorii care combină mai
multe piețe sau valute, folosiți măsurile `TradeValueReporting` și
`CommissionReporting` din `dw.FactTrade`. `TradeValue` și `CommissionAmount`
rămân valori în valuta originală și trebuie folosite numai împreună cu
dimensiunea `dw.DimCurrency`.

`dw.FactExchangeRate` conține cursurile istorice zilnice, iar relațiile cu
`dw.DimDate` și `dw.DimCurrency` permit analizarea evoluției cursurilor.

Măsurile principale recomandate sunt:

```DAX
Volum tranzacționat EUR =
SUM ( FactTrade[TradeValueReporting] )

Comisioane EUR =
SUM ( FactTrade[CommissionReporting] )

Valoare medie tranzacție EUR =
DIVIDE ( [Volum tranzacționat EUR], COUNTROWS ( FactTrade ) )
```

Formatați primele trei măsuri ca monedă EUR. Pentru analiza sumelor originale,
folosiți `TradeValue` numai într-un vizual filtrat sau grupat după
`DimCurrency[CurrencyCode]`.

Directorul conține documentația și capturile raportului. Fișierul editabil `.pbix` nu este versionat, deoarece `.gitignore` exclude fișierele binare Power BI.

## Prezentarea portofoliului

- valoarea totală a portofoliului;
- soldul de numerar;
- pozițiile și numărul de instrumente.

## Activitatea de tranzacționare

- ordine după stare, sens și instrument;
- execuții în timp și volum tranzacționat;
- preț mediu ponderat.

## Activitatea clienților

- clienți activi;
- ordine și volum pe client;
- detaliere client, cont și instrument.

## Risc și operațiuni

- ordine respinse sau anulate;
- execuții eșuate;
- venituri din comisioane și excepții operaționale.

Modelul Power BI consumă datele din `BrokerageDW`, evitând interogarea directă a tabelelor operaționale.

## Extensii pentru raportare

Importă din schema `dw`: `vwPowerBiCashFlow`,
`vwPowerBiPortfolioEvolution` și `vwPowerBiOrderLifecycle`.

```DAX
Flux net EUR = SUM ( vwPowerBiCashFlow[SumaEur] )

Valoare portofoliu EUR = SUM ( vwPowerBiPortfolioEvolution[ValoareTotalaEur] )

Timp mediu soluționare (minute) =
AVERAGE ( vwPowerBiOrderLifecycle[MinutePanaLaSolutionare] )
```

Folosește un grafic de evoluție pentru valoarea portofoliului, un grafic cu
fluxul net după tipul operațiunii și distribuția ordinelor după stare.
