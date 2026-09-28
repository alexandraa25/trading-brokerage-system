# Depozit de date

`BrokerageDW` este modelul analitic dimensional al aplicației. EUR este moneda consolidată de raportare.

## Instalare

Rulează scripturile `01`–`13` în ordine, apoi:

1. `15_create_fact_kyc.sql`;
2. `16_load_fact_kyc.sql`;
3. `17_upgrade_fact_order_lifecycle_stop_history.sql` pentru instalări existente cu ordine avansate;
4. `18_upgrade_fact_order_expiration.sql` pentru valabilitate și expirare;
5. `19_operational_audit_analytics.sql` pentru utilizatori și audit operațional;
6. `views/01_create_powerbi_views.sql`.

Actualizează întâi staging-ul prin `etl/07_refresh_staging_from_oltp.sql` înainte de încărcările noi.

## Fapte principale

- `FactTrade`: execuții, valori și comisioane în EUR;
- `FactExchangeRate`: cursuri BCE istorice;
- `FactCashTransaction`: depuneri, retrageri, decontări, comisioane și conversii;
- `FactPortfolioDailySnapshot`: valoare investită, poziții, numerar și total zilnic;
- `FactOrderLifecycle`: ordine, stare, timp până la soluționare, STOP, declanșare, valabilitate, expirare și cantități;
- `FactKyc`: stare, durată de soluționare și motivul respingerii.
- `FactOperationalAudit`: conectări, modificări de acces și activitate asupra ordinelor.

Vizualizările pentru Power BI sunt `dw.vwPowerBiCashFlow`, `dw.vwPowerBiPortfolioEvolution`, `dw.vwPowerBiOrderLifecycle` și `dw.vwPowerBiOperationalAudit`.

## Validare

Rulează validările din `tests/14_data_warehouse_validation.sql` până la `tests/23_admin_analytics_validation.sql`, plus `tests/24_advanced_order_validation.sql` pentru STOP, STOP-LIMIT, anulări parțiale și comisioane, `tests/25_order_expiration_dw_validation.sql` pentru valabilitatea și expirarea ordinelor și `tests/26_operational_audit_dw_validation.sql` pentru auditul operațional.
