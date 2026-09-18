# ETL

Acest director conține scripturile pentru schema intermediară și încărcările de date.

Ordinea recomandată este:

1. `01_create_staging.sql` creează tabelele intermediare;
2. `02_initial_load.sql` execută încărcarea completă inițială;
3. `03_create_etl_control.sql` creează marcajele și jurnalul rulărilor;
4. `04_incremental_dimensions.sql` actualizează clienții, conturile, piețele și instrumentele;
5. `04_incremental_load.sql` actualizează ordinele;
6. `05_incremental_append_only.sql` încarcă execuțiile și tranzacțiile de numerar.

Încărcările incrementale folosesc o fereastră temporală fixă, previn duplicatele și actualizează marcajul numai după finalizarea cu succes a tranzacției.
