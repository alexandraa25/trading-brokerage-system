# ETL

Acest director pregătește datele operaționale din `BrokerageDB` pentru încărcarea în `BrokerageDW`.

## Ordine de instalare și rulare

1. `01_create_staging.sql` creează schema de staging;
2. `02_initial_load.sql` încarcă datele inițiale;
3. `03_create_etl_control.sql` creează jurnalul și marcajele ETL;
4. `04_incremental_dimensions.sql` actualizează dimensiunile;
5. `05_incremental_orders.sql` actualizează ordinele;
6. `06_incremental_append_only.sql` încarcă execuții și tranzacții de numerar;
7. `07_refresh_staging_from_oltp.sql` reconstruiește staging-ul complet;
8. `08_currency_reporting_eur.sql` completează valorile de raportare EUR;
9. `09_stop_order_history_upgrade.sql` actualizează staging-ul cu STOP, cantități inițiale și anulări parțiale;
10. `10_order_expiration_upgrade.sql` adaugă valabilitatea și data expirării ordinelor.
11. `11_refresh_audit_staging.sql` reîmprospătează utilizatorii aplicației și jurnalele de conectare, acces și ordine.

Pentru o bază existentă, rulează `09_stop_order_history_upgrade.sql` și `10_order_expiration_upgrade.sql` după `database/20_order_history_quantities.sql`, apoi rulează `07_refresh_staging_from_oltp.sql`.

## Date încărcate

Staging-ul include datele clientului, conturilor, instrumentelor, cursurilor BCE, numerarului, execuțiilor, snapshoturilor de portofoliu, KYC și ciclului de viață al ordinelor. Pentru ordinele avansate sunt păstrate tipul, prețul STOP, limita, valabilitatea, expirarea, cantitățile comandate/executate/anulate și starea de declanșare.

Pentru raportarea operațională, `staging.ApplicationUser` și `staging.OperationalAudit` reunesc acțiunile din sesiunile de autentificare, jurnalul de acces și jurnalul ordinelor.

Încărcările incrementale folosesc tranzacții și marcaje de control: marcajul avansează numai după finalizarea cu succes a operației.
