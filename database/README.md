# Baza operațională

`BrokerageDB` este baza operațională folosită de API. Ea păstrează datele clienților, KYC, conturi, numerar, instrumente, cotații, ordine, execuții, audit și notificări. Pentru Power BI, datele sunt extrase ulterior în `BrokerageDW`.

## Diagramă ERD

[erd.png](erd.png) este diagrama pentru vizualizare rapidă. Sursa editabilă este
[erd.svg](erd.svg) și include structura actuală pentru `security`, `core`,
`trading` și `audit`, inclusiv ordinele avansate, sesiunile și jurnalele noi.

## Instalare

Rulează scripturile în ordine numerică:

1. `01_create_database_schemas_tables.sql` și `02_seed_data.sql`;
2. `04_currency_conversion_eur.sql` până la `16_watchlist_price_alerts.sql`;
3. `17_advanced_orders.sql` până la `21_order_expiration.sql`;
4. `22_security_activity_audit.sql` și `23_session_revocation.sql`.

Scripturile `17`–`21` adaugă ordine STOP/STOP-LIMIT, procedurile actualizate, cantitățile de istoric și valabilitatea ordinelor. Scriptul `22` creează jurnalele pentru autentificări și activitatea ordinelor. Scriptul `23` adaugă versiunea de sesiune necesară pentru deconectarea tuturor sesiunilor unui utilizator.

După instalare, rulează scripturile din subdirectoarele `procedures/`, `triggers/`, `views/` și `indexes/` dacă acestea nu au fost incluse în instalarea inițială.

## Date demonstrative

- `demo/01_seed_diverse_demo_data.sql`: clienți, conturi, ordine și tranzacții diverse;
- `demo/02_seed_advanced_order_demo.sql`: ordine STOP/STOP-LIMIT, ordine declanșate și anulări parțiale.

Rulează `demo/02_seed_advanced_order_demo.sql` după scripturile `17`–`21`.

## Audit și reguli

- `audit.UserSessionHistory`: autentificări și dispozitive;
- `audit.OrderActivityLog`: estimări, anulări parțiale și activări STOP;
- `audit.AccessAuditLog`: modificări de acces ale personalului;
- `audit.AccountAdministrationLog`: suspendări și reactivări de cont;
- triggerele păstrează istoricul KYC, clienților, utilizatorilor și ordinelor.

EUR rămâne moneda de raportare; cursurile BCE și conversiile sunt păstrate cu data utilizată la operațiune.
