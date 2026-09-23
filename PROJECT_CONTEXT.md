# Context proiect: Trading Brokerage System

## Scop

Aplicație de brokerage cu SQL Server, API ASP.NET Core și interfață Angular.
Moneda principală de raportare este EUR. Cursurile valutare provin din BCE și
sunt păstrate zilnic în baza de date.

## Structură

- `database/` — schema SQL, proceduri, date demonstrative și import curs BCE.
- `api/Brokerage/` — API .NET 10, autentificare JWT și Swagger.
- `web/brokerage-ui/` — aplicația Angular 20 pentru client.
- `automation/` — actualizare zilnică a cursurilor BCE.

## Configurare locală

- SQL Server: `localhost`, baza de date `BrokerageDB`.
- API: `https://localhost:7103` și `http://localhost:5018`.
- Swagger: `https://localhost:7103/swagger`.
- Angular: `http://localhost:4200` prin `npm start` în `web/brokerage-ui`.
- Cheia JWT se păstrează în User Secrets, sub `Jwt:Key`; nu se salvează în Git.

## Utilizatori demonstrativi

| Rol | Email | Parolă |
| --- | --- | --- |
| Client | `customer.demo@brokerage.local` | `DemoCustomer!2026` |
| Broker | `broker.demo@brokerage.local` | `DemoBroker!2026` |
| Administrator | `admin.demo@brokerage.local` | `DemoAdmin!2026` |

## Funcții implementate

- Autentificare JWT, roluri și restricționarea accesului la datele clientului.
- Conturi, numerar, poziții, instrumente, ordine, execuții și anulare ordine.
- Conversie și raportare în EUR cu curs BCE.
- Swagger pentru testarea API-ului.
- Dashboard Angular cu taburi: prezentare generală, instrumente,
  tranzacționare și istoric ordine.
- Componente Angular separate pentru login, rezumat, numerar, poziții,
  instrumente, formular ordine și istoric ordine.
- Listă separată pentru conturile clientului și feedback vizual pentru ordine.
- Cotații simulate zilnice în `trading.MarketQuote`, marcate
  `SIMULATED_DAILY`; sunt potrivite pentru demonstrația de portofoliu.
- Endpoint `GET /api/accounts/{accountId}/valuation` care calculează
  investiția inițială, valoarea curentă, profitul/pierderea și procentul în
  EUR, folosind cotațiile simulate și cursurile BCE.
- Dashboard cu valoarea portofoliului, investiția inițială,
  profit/pierdere în EUR și procent, plus grafic simulat pe 7 zile.
- Panou Broker în Angular, vizibil exclusiv pentru rolul `Broker`, cu ordine
  în așteptare și execuții complete sau parțiale prin API.
- Pentru performanță, API-ul brokerului livrează doar cele mai recente 100 de
  ordine active; panoul are filtru Cumpărare/Vânzare și detalii de execuție.
- Înainte de execuție, brokerul primește o confirmare cu ordinul, cantitatea,
  prețul și valoarea estimată.
- Panoul brokerului reîncarcă automat ordinele active și execuțiile la fiecare
  25 de secunde și notifică apariția unor ordine noi.
- Panou Administrator/KYC separat, vizibil exclusiv rolului `Administrator`:
  dosare cu căutare, filtrare după stare și acțiuni de aprobare/respingere.
  Respingerea cere un motiv într-o fereastră de confirmare; lista este
  paginată cu câte 10 dosare pe pagină.
- Administratorul are și tabul „Jurnal audit”, alimentat din `audit.AuditLog`:
  afișează modificările KYC, utilizatorul, momentul și valorile înainte/după,
  cu paginare.
- Panoul administrator are un design vizual propriu: antet colorat, taburi
  tip selector, carduri cu spațiere îmbunătățită, tabele responsive și stări
  KYC ușor de diferențiat.
- Clientul poate înregistra depuneri de numerar din dashboard. Interfața
  folosește endpointul existent pentru procedura `trading.usp_DepositCash`,
  iar soldurile și valoarea totală în EUR se reîncarcă după confirmare.
- Clientul are tabul „Istoric numerar”, care reunește operațiunile reale ale
  conturilor sale de numerar, cu filtrare după tip și paginare.
- Istoric real zilnic al portofoliului în `reporting.PortfolioDailySnapshot`,
  actualizat prin `reporting.usp_CapturePortfolioDailySnapshot`. Dashboardul
  afișează graficul alimentat din API pentru 7 zile, 30 de zile, 12 săptămâni
  sau o perioadă aleasă de utilizator.
- Importatorul zilnic BCE actualizează și cotațiile simulate, apoi execută
  capturarea zilnică a valorii portofoliului, pentru a extinde automat graficul.
- Clientul are tabul „Profil și verificare”, cu starea KYC, datele dosarului
  și motivul respingerii, când este cazul.
- Clientul poate înregistra retrageri de numerar. Procedura SQL validează KYC,
  starea contului și soldul disponibil înainte să creeze operațiunea de tip
  `Withdrawal` în istoricul de numerar.
- Notificări persistente pentru client: clopoțel cu număr de mesaje necitite,
  marcarea notificărilor ca citite și actualizare la 30 de secunde. Sunt create
  pentru depuneri, retrageri, aprobarea/respingerea KYC și executarea ordinelor.
- Schimb valutar între conturile clientului, la ultimul curs oficial BCE
  disponibil. `trading.CurrencyConversion` păstrează definitiv suma sursă,
  suma primită, cursul aplicat, cursurile către EUR și datele lor, astfel încât
  istoricul conversiei nu se modifică după actualizările ulterioare de curs.
- Monedă de afișare pentru dashboard: clientul poate alege EUR sau o monedă
  disponibilă în cursurile BCE; valorile sumare și graficul se convertesc doar
  vizual. Soldurile și operațiunile rămân în monedele lor reale.
- Filtru de portofoliu după moneda reală: prin selectarea EUR, USD, RON etc.,
  rezumatul curent, pozițiile și soldurile arată numai activele denominate în
  moneda respectivă. Acesta este independent de moneda de afișare vizuală.
- Din formularul de depunere, clientul poate deschide un cont de numerar nou
  pentru un cont de tranzacționare și o monedă aleasă, apoi poate depune în el.
- Catalogul de instrumente afișează acum tipul, emitentul, piața, moneda,
  ultima cotație simulată și data ei; include și explicații pentru acțiuni,
  ETF-uri și obligațiuni, cu căutare și filtrare după tip.
- Brokerul are tabul „Prezentare broker” cu indicatori pentru ordine active,
  execuții, volum și ordine parțiale. Din ordine active poate deschide datele
  ordinului, clientului, contului, disponibilului și poziției înainte de
  confirmarea execuției.
- Brokerul poate respinge un ordin activ cu motiv obligatoriu. Decizia este
  păstrată în `audit.OrderDecision`, ordinul primește starea `Rejected`, iar
  clientul primește o notificare.
- Lista de ordine active a brokerului acceptă filtrare după simbol, sens,
  tip, interval de date și sortare după dată sau cantitate. Fiecare ordin
  afișează momentul plasării, iar paginarea se resetează când filtrul se
  modifică.
- Panoul brokerului arată momentul ultimei actualizări, actualizează automat
  comenzile și execuțiile la fiecare 25 de secunde și permite actualizare
  manuală din interfață.
- Brokerul primește alerte vizibile pentru ordine noi și pentru ordine active
  neexecutate de peste 15 minute. Zona „Alerte broker” permite deschiderea
  directă a ordinului din alertă pentru verificare, execuție sau respingere;
  alertele sunt paginate câte 5 pe pagină.
- Export broker: `GET /api/broker/orders/history` oferă ultimele 500 ordine
  pentru broker sau administrator, iar interfața descarcă CSV separat pentru
  istoricul ordinelor și istoricul execuțiilor. Fișierele includ antete în
  română și codare compatibilă cu Excel.
- Panoul brokerului permite selectarea monedei pentru afișarea volumelor și
  a valorilor/comisioanelor execuțiilor. Tabul „Schimb valutar” arată cursurile
  BCE disponibile și precizează că execuțiile păstrează cursul istoric de la
  momentul înregistrării; schimbarea selectorului este doar vizuală.
- Fereastra de execuție a brokerului arată ultima cotație salvată a
  instrumentului și precompletează prețul de execuție. Înainte de confirmare,
  validează cantitatea rămasă, limita ordinului, soldul plus comisionul de
  0,25% pentru cumpărare și poziția disponibilă pentru vânzare, afișând motivul
  concret dacă execuția nu poate fi făcută.
- Notificări broker persistente: `audit.BrokerNotification` și endpointurile
  `api/broker/notifications` salvează și expun notificări comune echipei de
  brokeri. Clopoțelul brokerului arată ordine noi, execuții reușite și
  execuții blocate; poate marca o notificare sau toate notificările ca citite.
- Înregistrare client: `POST /api/registration` creează clientul, utilizatorul
  de autentificare, contul de tranzacționare EUR, contul de numerar EUR și
  dosarul KYC în starea `Pending`, într-o singură tranzacție. Ecranul de login
  include formularul „Creează cont client”. Administratorul poate folosi
  `POST /api/registration/admin` pentru înregistrare manuală.
- Tabul „Clienți” al administratorului include formularul „Creare manuală”
  pentru prenume, nume, email și parolă inițială; după creare reîncarcă lista
  clienților și dosarele KYC.
- Administratorul are tabul „Clienți”, cu căutare, filtre după starea
  profilului, paginare și acțiuni de activare, dezactivare sau blocare.
  `api/admin/customers` expune lista și actualizează starea clientului,
  trimițând și notificarea aferentă clientului.
- Din lista „Clienți”, administratorul poate deschide rezumatul unui client:
  conturi, solduri disponibile/blocate și poziții curente.
- Monitorizare administrator: tabul „Monitorizare” afișează clienți activi,
  KYC în așteptare, ordine active și execuții zilnice, plus alerte pentru KYC
  întârziat, clienți blocați și curs BCE neactualizat. API-ul include și
  endpointuri administrative pentru suspendarea/reactivarea conturilor și
  gestionarea utilizatorilor broker/administrator, inclusiv resetarea parolei.
- Tabelul `core.KYC` are trigger de audit; contextul EF îl declară explicit,
  astfel încât actualizarea stării KYC funcționează și cu trigger-ul activ.
- Depozitul de date include `dw.FactCashTransaction`, cu granularitate de o
  mișcare de numerar. Acesta leagă depunerile, retragerile, decontările,
  comisioanele și conversiile de dimensiunile dată, client, cont și monedă.
  Păstrează suma originală, cursul istoric către EUR, sursa cursului și suma
  raportată în EUR. Pentru conversii, cursul istoric este cel salvat în
  `trading.CurrencyConversion`; pentru celelalte operațiuni este ultimul curs
  disponibil la data mișcării. Scripturile sunt
  `warehouse/08_create_fact_cash_transaction.sql` și
  `warehouse/09_load_fact_cash_transaction.sql`, iar validarea este
  `tests/19_cash_transaction_dw_validation.sql`.
- Depozitul de date include `dw.FactPortfolioDailySnapshot`, cu granularitate
  de un cont de tranzacționare pe zi. Acesta încarcă valoarea investită,
  valoarea pozițiilor, numerarul și valoarea totală în EUR din
  `reporting.PortfolioDailySnapshot`. Scripturile sunt
  `warehouse/10_create_fact_portfolio_daily_snapshot.sql` și
  `warehouse/11_load_fact_portfolio_daily_snapshot.sql`, iar validarea este
  `tests/20_portfolio_snapshot_dw_validation.sql`.
- Depozitul de date include `dw.FactOrderLifecycle`, cu un rând pentru fiecare
  ordin. Acesta păstrează starea, cantitatea comandată/executată, numărul de
  execuții, data și durata soluționării, plus motivul unei respingeri. Scripturile
  sunt `warehouse/12_create_fact_order_lifecycle.sql` și
  `warehouse/13_load_fact_order_lifecycle.sql`, iar validarea este
  `tests/21_order_lifecycle_dw_validation.sql`.
- Vizualizările `dw.vwPowerBiCashFlow`, `dw.vwPowerBiPortfolioEvolution` și
  `dw.vwPowerBiOrderLifecycle` pregătesc datele pentru Power BI prin
  `warehouse/14_create_powerbi_views.sql`.
- Fluxul zilnic este automatizat prin
  `automation/Run-DailyDataPipeline.ps1`: import BCE, cotații și snapshoturi,
  refresh staging, dimensiuni și toate faptele DW. Sarcina Windows
  `TradingBrokerage-Daily-Data-Pipeline` a fost configurată la 17:15 și
  jurnalizează rulările în `automation/logs/`. Power BI Desktop se
  reîmprospătează după flux; pentru Power BI Service este necesar gateway local
  și o reîmprospătare programată după 17:30.
- Depozitul de date include `dw.FactKyc`, cu un rând pentru fiecare dosar:
  stare, document, data depunerii, data soluționării, număr de zile și motivul
  respingerii. Scripturile sunt `warehouse/15_create_fact_kyc.sql` și
  `warehouse/16_load_fact_kyc.sql`, iar validarea este
  `tests/22_kyc_dw_validation.sql`. Pentru dosarele istorice fără `VerifiedAt`,
  data de actualizare este folosită ca rezervă pentru data soluționării.

## Convenții front-end

- Modele comune: `web/brokerage-ui/src/app/core/models.ts`.
- Apeluri API: `web/brokerage-ui/src/app/core/api.service.ts`.
- Componente funcționale: `web/brokerage-ui/src/app/features/`.
- Nu se pun adrese API sau tipuri duplicate în componente când pot fi în
  serviciu sau modele comune.

## Următorii pași recomandați

1. Actualizarea raportului Power BI existent cu noile vizualizări analitice.
2. Teste automate pentru API și Angular.
3. Pregătirea configurării pentru publicare.

## Regulă de continuitate

După fiecare etapă importantă implementată, actualizez acest document cu
funcțiile noi, fișierele relevante, deciziile tehnice și următorii pași.
Nu se salvează chei, parole sau alte secrete în acest document.
