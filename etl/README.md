# ETL

Acest director conține scripturile pentru schema intermediară și încărcările de date.

Ordinea recomandată este:

1. `01_create_staging.sql` creează tabelele intermediare;
2. `02_initial_load.sql` execută încărcarea completă inițială;
3. `03_create_etl_control.sql` creează marcajele și jurnalul rulărilor;
4. `04_incremental_dimensions.sql` actualizează clienții, conturile, piețele și instrumentele;
5. `05_incremental_orders.sql` actualizează ordinele;
6. `06_incremental_append_only.sql` încarcă execuțiile și tranzacțiile de numerar;
7. `07_refresh_staging_from_oltp.sql` reconstruiește staging-ul complet din baza operațională;
8. `08_currency_reporting_eur.sql` completează datele de raportare în EUR.
9. `09_stop_order_history_upgrade.sql` actualizează staging-ul existent pentru
   ordine STOP, cantități inițiale și anulări parțiale.

Încărcările incrementale folosesc o fereastră temporală fixă, previn duplicatele și actualizează marcajul numai după finalizarea cu succes a tranzacției.

Pentru instalările existente, rulează `09_stop_order_history_upgrade.sql` după
`database/20_order_history_quantities.sql`, înainte de reîmprospătarea completă
prin `07_refresh_staging_from_oltp.sql`.
