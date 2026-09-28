# Pagina Power BI — Ordine avansate

## Sursă de date

După rularea ETL-ului, reîmprospătează `dw.vwPowerBiOrderLifecycle` și
`dw.FactTrade`. Pagina folosește în principal vizualizarea ciclului de viață
al ordinului, iar comisioanele în EUR provin din `FactTrade`.

## Măsuri DAX

```DAX
Ordine avansate =
CALCULATE (
    COUNTROWS ( vwPowerBiOrderLifecycle ),
    vwPowerBiOrderLifecycle[TipOrdin] IN { "STOP", "STOP_LIMIT" }
)

Ordine declanșate =
CALCULATE (
    [Ordine avansate],
    vwPowerBiOrderLifecycle[Stare] = "Triggered"
)

Ordine în așteptare declanșare =
CALCULATE (
    [Ordine avansate],
    vwPowerBiOrderLifecycle[Stare] = "WaitingTrigger"
)

Ordine neexecutate =
CALCULATE (
    COUNTROWS ( vwPowerBiOrderLifecycle ),
    vwPowerBiOrderLifecycle[CantitateRamasa] > 0,
    NOT vwPowerBiOrderLifecycle[Stare] IN { "Cancelled", "Rejected", "Expired" }
)

Ordine expirate =
CALCULATE (
    COUNTROWS ( vwPowerBiOrderLifecycle ),
    vwPowerBiOrderLifecycle[Stare] = "Expired"
)

Rată declanșare STOP =
DIVIDE ( [Ordine declanșate], [Ordine avansate], 0 )

Timp mediu până la declanșare =
AVERAGE ( vwPowerBiOrderLifecycle[MinutePanaLaDeclansare] )

Volum comandat =
SUM ( vwPowerBiOrderLifecycle[CantitateCeruta] )

Volum executat =
SUM ( vwPowerBiOrderLifecycle[CantitateExecutata] )

Volum anulat =
SUM ( vwPowerBiOrderLifecycle[CantitateAnulata] )

Comisioane EUR =
SUM ( FactTrade[CommissionReporting] )
```

Formatează `Rată declanșare STOP` ca procent și `Comisioane EUR` ca monedă
EUR.

## Aranjarea paginii

Pe primul rând adaugă patru carduri: `Ordine avansate`, `Ordine declanșate`,
`Rată declanșare STOP` și `Timp mediu până la declanșare`. Poți înlocui al
patrulea card cu `Ordine expirate` când vrei să urmărești ordinele DAY/DATE.

În stânga, folosește un grafic cu coloane grupate: axă `TipOrdin`, valori
`Volum comandat`, `Volum executat`, `Volum anulat`. În dreapta, pune un grafic
inelar cu `Stare` și numărul de ordine.

Sub ele, pune un grafic cu bare: axă `Symbol`, valoare `Ordine neexecutate`.
Lângă el, un grafic cu coloane pentru `Comisioane EUR` după `Symbol` sau
`TipInstrument`.

În partea de jos, adaugă un tabel cu: client, cont, simbol, tip ordin, stare,
preț STOP, preț limită, valabilitate, expiră la, cantitate cerută, executată,
anulată, rămasă, data declanșării și minute până la declanșare.

## Filtre și culori

Adaugă slicere pentru `DataCrearii`, `TipOrdin`, `Stare`, `Valabilitate`,
`ExpiraLa`, `Symbol`, `Client` și `Sens`.

Aplică formatare condițională pentru stare: `WaitingTrigger` albastru,
`Triggered` galben, `Executed` verde, `PartiallyExecuted` turcoaz,
`Cancelled`/cantitate anulată portocaliu, `Rejected` roșu și `Expired` gri.
