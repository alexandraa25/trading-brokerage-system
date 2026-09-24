# Baza operațională

`BrokerageDB` este baza folosită de API și de interfața Angular. Nu este sursa
directă pentru Power BI; datele analitice sunt încărcate ulterior în
`BrokerageDW`.

## Ordine de instalare

1. `01_create_database_schemas_tables.sql`
2. `02_seed_data.sql`
3. `04_currency_conversion_eur.sql`
4. `05_ecb_daily_exchange_rates.sql`
5. `06_api_identity.sql` până la `15_account_administration_audit.sql`
6. scripturile din `procedures/`, `triggers/`, `views/` și `indexes/`

Scriptul opțional `demo/01_seed_diverse_demo_data.sql` introduce date extinse
pentru demonstrații, teste și Power BI. Nu este necesar pentru aplicația de
bază.

## Rolul directoarelor

- `procedures/`: operații tranzacționale sigure;
- `triggers/`: jurnalizare automată și audit;
- `views/`: date pregătite pentru listări sau administrare;
- `indexes/`: optimizări pentru interogările frecvente;
- `demo/`: date demonstrative, separate de instalarea normală.
