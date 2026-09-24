# Depozit de date

Depozitul `BrokerageDW` este modelul analitic al aplicației. EUR este moneda de
raportare consolidată.

## Ordine de rulare

1. `01_create_warehouse.sql`
2. `02_create_dimensions.sql`
3. `03_create_facts.sql`
4. `04_load_dimensions.sql`
5. `05_load_fact_trade.sql`
6. `06_create_analytics_indexes.sql`
7. `07_currency_reporting_eur.sql`
8. `08_create_fact_cash_transaction.sql`
9. `09_load_fact_cash_transaction.sql`
10. `10_create_fact_portfolio_daily_snapshot.sql`
11. `11_load_fact_portfolio_daily_snapshot.sql`
12. `12_create_fact_order_lifecycle.sql`
13. `13_load_fact_order_lifecycle.sql`
14. `views/01_create_powerbi_views.sql`
15. `15_create_fact_kyc.sql`
16. `16_load_fact_kyc.sql`

Înainte de încărcările de la pașii 4, 5 și 9, actualizează staging-ul cu
`etl/07_refresh_staging_from_oltp.sql` atunci când ai date operaționale noi.

## Fapte disponibile

- `dw.FactTrade`: o execuție de ordin; conține valoare și comision în EUR.
- `dw.FactExchangeRate`: un curs valutar din sursa operațională.
- `dw.FactCashTransaction`: o mișcare de numerar. Conține depuneri, retrageri,
  decontări, comisioane și conversii valutare cu echivalentul istoric în EUR.
- `dw.FactPortfolioDailySnapshot`: valoarea zilnică în EUR a unui portofoliu,
  împărțită în valoare investită, poziții, numerar și valoare totală.
- `dw.FactOrderLifecycle`: un ordin, cu starea curentă, execuțiile, timpul
  până la soluționare și motivul respingerii, dacă există.
- `dw.FactKyc`: un dosar KYC, cu starea, data depunerii și soluționării,
  durata în zile și motivul respingerii.

Conversiile valutare utilizează cursurile păstrate în
`trading.CurrencyConversion`. Celelalte mișcări folosesc ultimul curs către
EUR disponibil la data operațiunii. EUR are cursul identitar 1.

`views/01_create_powerbi_views.sql` publică vizualizările `vwPowerBiCashFlow`,
`vwPowerBiPortfolioEvolution` și `vwPowerBiOrderLifecycle` pentru importul
direct în Power BI.

## Validare

După încărcare rulează:

```text
tests/14_data_warehouse_validation.sql
tests/17_currency_dw_validation.sql
tests/19_cash_transaction_dw_validation.sql
tests/20_portfolio_snapshot_dw_validation.sql
tests/21_order_lifecycle_dw_validation.sql
tests/22_kyc_dw_validation.sql
```
