# Ghidul datelor, SQL și analiticii

Acest proiect are două baze de date cu scopuri diferite:

```text
BrokerageDB (OLTP) → staging → BrokerageDW (dimensional) → Power BI
```

- **OLTP** înseamnă baza folosită zilnic de aplicație: clienți, conturi, bani, ordine și execuții.
- **staging** este zona temporară de pregătire a datelor pentru analiză.
- **BrokerageDW** este depozitul de date: păstrează fapte și dimensiuni pentru Power BI, nu pentru tranzacționarea live.

EUR este moneda de raportare. O operație păstrează cursul folosit atunci, astfel încât rapoartele istorice nu se modifică dacă un curs BCE se actualizează ulterior.

## Principii folosite

1. **Separarea operaționalului de analiză.** API-ul lucrează cu `BrokerageDB`; Power BI citește `BrokerageDW`.
2. **Integritatea datelor.** Cheile primare, cheile externe, `UNIQUE`, `CHECK` și `NOT NULL` opresc datele invalide direct în SQL Server.
3. **Atomicitate financiară.** Depunerile, retragerile, schimburile, crearea, execuția și anularea ordinelor sunt proceduri stocate cu tranzacții.
4. **Auditabilitate.** Trigger-ele și jurnalele păstrează cine, ce și când a modificat.
5. **Istoric corect.** Ordinele, cursurile, execuțiile și snapshoturile sunt păstrate cu dată.
6. **Performanță.** API-ul folosește EF Core cu `AsNoTracking`, filtre și paginare; SQL are indexuri pe traseele frecvente.
7. **ETL repetabil.** Staging-ul poate fi reîmprospătat, iar marcajele ETL avansează numai după succes.

## 1. Baza operațională: `database/`

Rulează mai întâi `01`, `02`, apoi `04`–`23`, în această ordine. Scriptul `03` nu există; numerotarea reflectă evoluția proiectului.

| Fișier | Ce face |
|---|---|
| `01_create_database_schemas_tables.sql` | Creează `BrokerageDB`, schemele `core`, `trading`, `audit` și tabelele de bază: tip client, client, KYC, cont, cont de numerar, piață, emitent, instrument, ordin, execuție, poziție, comision, tranzacție de numerar și audit inițial. Definește relațiile și regulile de integritate. |
| `02_seed_data.sql` | Introduce date minime: tipuri de clienți, piețe, emitenți, instrumente, clienți, conturi și date utile pentru demonstrație. |
| `04_currency_conversion_eur.sql` | Creează monedele, cursurile istorice către EUR și coloanele de raportare EUR pentru execuții. Include `core.usp_ConvertCurrency`, conversia generică bazată pe cursuri. |
| `05_ecb_daily_exchange_rates.sql` | Adaugă jurnalul importurilor BCE și sursa cursului la execuții. Separă proveniența cursului de valoarea cursului. |
| `06_api_identity.sql` | Creează identitățile aplicației în schema `security`: utilizatori, roluri, parolă hash și legătura opțională cu clientul. |
| `07_simulated_market_quotes.sql` | Creează `trading.MarketQuote` și proceduri pentru cotația zilei și istoric demonstrativ de cotații. Este sursa graficelor de instrumente. |
| `08_portfolio_daily_history.sql` | Creează snapshotul zilnic al portofoliului în EUR și `reporting.usp_CapturePortfolioDailySnapshot`. Este sursa evoluției portofoliului. |
| `09_cash_withdrawal.sql` | Creează `trading.usp_WithdrawCash`: verifică soldul, actualizează numerarul și înregistrează tranzacția. |
| `10_customer_notifications.sql` | Creează notificările persistente ale clienților și starea citit/necitit. |
| `11_currency_exchange.sql` | Creează `trading.usp_ConvertCash`; mută numerar între două conturi valutare și salvează cursurile BCE și valorile rezultate. |
| `12_broker_order_rejection.sql` | Creează `trading.usp_RejectOrder`, cu motivul obligatoriu al respingerii. |
| `13_broker_notifications.sql` | Creează notificările comune pentru brokeri. |
| `14_access_audit.sql` | Creează auditul pentru creare, activare, dezactivare și resetare de acces. |
| `15_account_administration_audit.sql` | Creează jurnalul suspendărilor/reactivărilor de cont și motivul administratorului. |
| `16_watchlist_price_alerts.sql` | Creează favoritele și alertele de preț ale clientului; `core.usp_CheckCustomerPriceAlerts` marchează alertele atinse. |
| `17_advanced_orders.sql` | Extinde tipurile de ordin cu STOP și STOP-LIMIT și introduce `usp_CancelOrderPartially`. |
| `18_advanced_order_creation.sql` | Actualizează `trading.usp_CreateOrder` pentru ordine avansate, prag STOP, limită și validări de fonduri. |
| `19_stop_order_activation.sql` | Adaugă stările `WaitingTrigger` și `Triggered`; o comandă STOP devine executabilă doar după atingerea pragului. |
| `20_order_history_quantities.sql` | Salvează cantitatea inițială, anulată, executată și rămasă; actualizează anularea parțială. |
| `21_order_expiration.sql` | Adaugă valabilitate `DAY`, `DATE`, `GTC`, data expirării și starea `Expired`. |
| `22_security_activity_audit.sql` | Creează jurnalul autentificărilor și jurnalul operațional al ordinelor. |
| `23_session_revocation.sql` | Adaugă versiunea sesiunii; creșterea ei invalidează toate tokenurile vechi ale utilizatorului. |

### Subdirectoarele `database/`

| Fișier | Ce face |
|---|---|
| `procedures/usp_DepositCash.sql` | Depunere atomică: actualizează soldul și adaugă mișcarea de numerar. |
| `procedures/usp_ExecuteOrder.sql` | Execuție atomică: verifică ordinul, fondurile/poziția, actualizează ordinul, poziția, numerarul, comisionul și execuția. |
| `procedures/usp_CancelOrder.sql` | Anulează complet un ordin activ și eliberează resursele blocate. |
| `procedures/usp_CreateOrder.sql` | Versiunea de bază a procedurii de creare; pentru funcțiile avansate este suprascrisă de scripturile 18 și 19. |
| `triggers/trg_Order_StatusHistory.sql` | La schimbarea stării ordinului, scrie automat în `audit.OrderStatusHistory`. |
| `triggers/trg_Audit_TradingWorkflow.sql` | Auditează modificările pentru ordin, client, KYC, cont și execuție. Trigger-ele observă modificarea; nu conțin logica financiară principală. |
| `views/vw_CustomerCash.sql` | Expune soldul de numerar al clienților într-un format ușor de citit. |
| `views/vw_OrderDetails.sql` | Unește ordinul cu instrumentul, contul și clientul pentru ecrane și verificări. |
| `views/vw_Portfolio.sql` | Expune pozițiile și valorile portofoliului pentru interogări operaționale. |
| `indexes/01_order_indexes.sql` | Creează indexuri pentru ordine, tranzacții de numerar și execuții; accelerează filtrele după cont, stare, instrument și dată. |
| `demo/01_seed_diverse_demo_data.sql` | Adaugă date demonstrative diverse pentru clienți, monede, ordine și tranzacții. Rulează-l manual, nu ca bootstrap repetabil. |
| `demo/02_seed_advanced_order_demo.sql` | Adaugă exemple STOP, STOP-LIMIT, declanșate și anulate parțial. Necesită 19–21. |

## 2. ETL și staging: `etl/`

Staging-ul este o copie structurată a datelor necesare analizei. Nu este sursa adevărului și poate fi recreat din `BrokerageDB`.

| Fișier | Ce face |
|---|---|
| `01_create_staging.sql` | Creează schema `staging` și copii pentru client, cont, piață, instrument, ordin, execuție și tranzacție de numerar. |
| `02_initial_load.sql` | Încarcă pentru prima dată staging-ul din `BrokerageDB`. |
| `03_create_etl_control.sql` | Creează `ETLWatermark` și `ETLRunLog`: data ultimei încărcări și jurnalul rulărilor. |
| `04_incremental_dimensions.sql` | Actualizează incremental datele descriptive: client, cont, piață, instrument. |
| `05_incremental_orders.sql` | Actualizează incremental ordinele modificate după marcaj. |
| `06_incremental_append_only.sql` | Încarcă incremental execuțiile și mișcările de numerar, considerate evenimente adăugate. |
| `07_refresh_staging_from_oltp.sql` | Reîmprospătează complet staging-ul; este util înainte de o încărcare completă în DW. |
| `08_currency_reporting_eur.sql` | Adaugă în staging instantaneul valutar EUR al execuției. |
| `09_stop_order_history_upgrade.sql` | Extinde staging-ul cu STOP, limită, cantitate inițială și anulată. |
| `10_order_expiration_upgrade.sql` | Adaugă valabilitatea și data de expirare în staging. |
| `11_refresh_audit_staging.sql` | Copiază utilizatorii și auditul de conectare, acces și ordine pentru analiza operațională. |

**Principiu ETL:** extragere din OLTP, transformare în staging, încărcare în DW. O tranzacție ETL eșuată nu trebuie să avanseze watermark-ul, altfel ar pierde evenimente.

## 3. Depozitul de date: `warehouse/`

Depozitul folosește model dimensional: **dimensiunile** răspund la „cine, ce, unde, când?”, iar **faptele** răspund la „ce s-a întâmplat și cât a fost valoarea?”.

| Fișier | Ce face |
|---|---|
| `01_create_warehouse.sql` | Creează `BrokerageDW` și schema `dw`. |
| `02_create_dimensions.sql` | Creează `DimDate`, `DimCustomer`, `DimAccount`, `DimInstrument`, `DimCurrency`. |
| `03_create_facts.sql` | Creează `FactTrade` și `FactExchangeRate`. |
| `04_load_dimensions.sql` | Încarcă și actualizează dimensiunile din staging. |
| `05_load_fact_trade.sql` | Încarcă execuțiile în `FactTrade`, cu curs și valori EUR. |
| `06_create_analytics_indexes.sql` | Creează indexuri pentru filtrele analitice după dată, client, cont și instrument. |
| `07_currency_reporting_eur.sql` | Completează suportul de raportare valutară EUR în depozit. |
| `08_create_fact_cash_transaction.sql` | Creează `FactCashTransaction`. |
| `09_load_fact_cash_transaction.sql` | Încarcă depuneri, retrageri, comisioane, decontări și conversii. |
| `10_create_fact_portfolio_daily_snapshot.sql` | Creează `FactPortfolioDailySnapshot`. |
| `11_load_fact_portfolio_daily_snapshot.sql` | Încarcă evoluția zilnică: investit, poziții, numerar și total EUR. |
| `12_create_fact_order_lifecycle.sql` | Creează `FactOrderLifecycle`, un rând per ordin. |
| `13_load_fact_order_lifecycle.sql` | Încarcă starea și timpul de soluționare al ordinelor. |
| `15_create_fact_kyc.sql` | Creează `FactKyc`, un rând per dosar KYC. |
| `16_load_fact_kyc.sql` | Încarcă starea KYC, datele, durata și motivul respingerii. |
| `17_upgrade_fact_order_lifecycle_stop_history.sql` | Adaugă STOP, cantități executate/anulate/rămase și timpul până la declanșare. |
| `18_upgrade_fact_order_expiration.sql` | Adaugă valabilitate, expirare și starea `Expired`. |
| `19_operational_audit_analytics.sql` | Creează `DimApplicationUser` și `FactOperationalAudit`. |
| `views/01_create_powerbi_views.sql` | Creează view-uri curate pentru Power BI: flux de numerar, evoluție portofoliu, ciclu de viață ordine și audit operațional. |

### Cum se citesc faptele

- `FactTrade`: granularitate = **o execuție**.
- `FactCashTransaction`: granularitate = **o mișcare de numerar**.
- `FactPortfolioDailySnapshot`: granularitate = **un cont într-o zi**.
- `FactOrderLifecycle`: granularitate = **un ordin**.
- `FactKyc`: granularitate = **un dosar KYC**.
- `FactOperationalAudit`: granularitate = **o acțiune auditată**.

Nu aduna toate snapshoturile de portofoliu pentru a obține valoarea curentă; selectează ultima dată disponibilă.

## 4. Teste SQL: `tests/`

Rulează testele pe o bază de test sau citește cu atenție comentariile. Unele folosesc `ROLLBACK`, altele sunt numai citire.

| Test | Ce verifică |
|---|---|
| `01_seed_validation.sql` | Datele inițiale și relațiile de bază. |
| `02_deposit_tests.sql` | Depunerea și actualizarea soldului. |
| `03_order_tests.sql` | Crearea ordinelor și validările lor. |
| `04_execution_tests.sql` | Execuția și modificarea poziției/numerarului. |
| `05_performance_tests.sql` | Planuri și timp pentru interogările importante. |
| `06_transaction_rollback.sql` | Atomicitatea: o eroare nu lasă date parțiale. |
| `07_concurrency_locking.sql` | Blocarea și concurența la operații simultane. |
| `08_double_execution.sql` | Previne executarea dublă a aceluiași ordin. |
| `09_partial_execution.sql` | Execuții parțiale, cantitate rămasă și stare. |
| `10_sell_position_validation.sql` | Nu permite vânzarea peste poziția deținută. |
| `11_constraint_error_tests.sql` | PK, FK, e-mail unic și reguli `CHECK`. |
| `12_audit_status_history.sql` | Trigger-ul istoricului de stare și auditul ordinelor. |
| `13_etl_failure_rollback.sql` | ETL eșuat: rollback și watermark neschimbat. |
| `14_data_warehouse_validation.sql` | Dimensiuni, fapte, chei și măsuri din DW. |
| `15_end_to_end_workflow.sql` | Flux complet într-o tranzacție anulată la final. |
| `16_currency_conversion.sql` | Conversie și păstrarea cursului istoric în EUR. |
| `17_currency_dw_validation.sql` | Cursuri și valori EUR în depozit. |
| `18_administrative_rules_validation.sql` | KYC respins, suspendare și reactivare auditată. |
| `19_cash_transaction_dw_validation.sql` | `FactCashTransaction`. |
| `20_portfolio_snapshot_dw_validation.sql` | `FactPortfolioDailySnapshot`. |
| `21_order_lifecycle_dw_validation.sql` | `FactOrderLifecycle`. |
| `22_kyc_dw_validation.sql` | `FactKyc`. |
| `23_admin_analytics_validation.sql` | Indicatorii administratorului și seturile Power BI. |
| `24_advanced_order_validation.sql` | STOP, STOP-LIMIT, comision și anulare parțială. |
| `25_order_expiration_dw_validation.sql` | Valabilitatea și expirarea din DW. |
| `26_operational_audit_dw_validation.sql` | `DimApplicationUser` și `FactOperationalAudit`. |

## Flux recomandat de rulare zilnică

1. actualizezi cotațiile și cursurile BCE;
2. rulezi `reporting.usp_CapturePortfolioDailySnapshot`;
3. rulezi `etl/07_refresh_staging_from_oltp.sql` sau încărcările incrementale 04–06;
4. încarci dimensiunile și faptele din `warehouse/`;
5. reîmprospătezi Power BI din view-urile `dw.vwPowerBi...`;
6. rulezi testele de validare relevante.

## Ce explici la interviu

„Am separat baza operațională de depozitul analitic. Procedurile stocate protejează operațiile financiare atomice, trigger-ele creează audit, iar ETL-ul mută datele prin staging într-un model dimensional. Power BI citește view-uri pregătite pentru analiză, nu tabelele operaționale.”
