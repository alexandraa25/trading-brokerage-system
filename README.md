# Trading Brokerage System

Aplicație demonstrativă de brokeraj, cu trei roluri: client, broker și administrator. EUR este moneda principală de raportare. Proiectul include aplicația Angular, API-ul ASP.NET Core, baza operațională SQL Server, fluxul ETL, depozitul de date și raportarea Power BI.

## Funcționalități actuale

### Client

- conturi de numerar în mai multe monede, depuneri, retrageri și conversii la curs BCE păstrat istoric;
- portofoliu în EUR sau moneda aleasă, poziții, istoric, favorite și alerte de preț;
- ordine MARKET, LIMIT, STOP și STOP-LIMIT, cu estimare API pentru comision și disponibil;
- anulare totală sau parțială, valabilitate `DAY`, `DATE` și `GTC`;
- profil, KYC, notificări, schimbare parolă și avertizare înainte de expirarea sesiunii.

### Broker

- ordine active și ordine STOP în așteptare, cu filtre, paginare și actualizare periodică;
- detalii de ordin, execuție totală/parțială, respingere cu motiv și verificarea limitei STOP-LIMIT;
- istoric de execuții, curs BCE, alerte și export CSV;
- profil și securitate.

### Administrator

- KYC, clienți, conturi, conturi de numerar și utilizatori ai personalului;
- suspendare/reactivare cu motiv și reguli KYC;
- deconectarea tuturor sesiunilor unui broker sau administrator;
- monitorizare operațională, Power BI și Asistent AI;
- jurnal audit cu subtaburi pentru KYC și activitatea ordinelor, filtre, paginare și export CSV.

### Date și analiză

- cursuri BCE, cotații simulate și snapshoturi zilnice de portofoliu;
- ETL din `BrokerageDB` către `BrokerageDW`;
- fapte pentru tranzacții, numerar, portofoliu, ordine avansate și KYC;
- Power BI pentru portofoliu, numerar, ordine și ordine STOP/STOP-LIMIT.

## Arhitectură

```text
Angular → ASP.NET Core API → BrokerageDB → staging → BrokerageDW → Power BI
                                      ↑
                           BCE + cotații simulate
```

## Pornire locală

1. Rulează scripturile SQL din [database/README.md](database/README.md), inclusiv `22_security_activity_audit.sql` și `23_session_revocation.sql`.
2. Configurează `Jwt:Key` local pentru API; instrucțiunile sunt în [api/Brokerage/README.md](api/Brokerage/README.md).
3. Pornește API-ul din `api/Brokerage/Brokerage` cu `dotnet run`.
4. Pornește Angular din `web/brokerage-ui` cu `npm install` și `npm start`.

Swagger: `https://localhost:7103/swagger` · Interfață: `http://localhost:4200`.

## Pornire cu Docker

Docker pornește SQL Server, API-ul și interfața, inițializând automat `BrokerageDB`, `BrokerageDW`, ETL-ul și datele demonstrative. Copiază `.env.example` ca `.env`, apoi rulează:

```powershell
docker-compose up --build
```

Interfața devine disponibilă la `http://localhost:4200`, iar Swagger la `http://localhost:8080/swagger`. Instrucțiunile complete, inclusiv resetarea datelor și conectarea Power BI, sunt în [docker/README.md](docker/README.md).

## Conturi demonstrative

| Rol | Email | Parolă |
| --- | --- | --- |
| Client | `customer.demo@brokerage.local` | `DemoCustomer!2026` |
| Broker | `broker.demo@brokerage.local` | `DemoBroker!2026` |
| Administrator | `admin.demo@brokerage.local` | `DemoAdmin!2026` |

## Documentație pe directoare

- [API](api/Brokerage/README.md)
- [Interfață Angular](web/brokerage-ui/README.md)
- [Structura Angular](web/brokerage-ui/src/app/README.md)
- [Baza operațională](database/README.md)
- [ETL](etl/README.md)
- [Depozit de date](warehouse/README.md)
- [Automatizare](automation/README.md)
- [Power BI](powerbi/README.md)
- [Docker](docker/README.md)

## Testare

- Angular: `npm run test:ci` din `web/brokerage-ui`;
- API: `dotnet test Brokerage.Api.Tests/Brokerage.Api.Tests.csproj` din `api/Brokerage`;
- SQL: rulează scripturile relevante din `tests/`, inclusiv `24_advanced_order_validation.sql` după instalarea ordinelor avansate.

Proiectul este demonstrativ: cotațiile instrumentelor sunt simulate. Cursurile BCE, prețurile și valorile de raportare rămân stocate istoric pentru consistența tranzacțiilor și rapoartelor.

Memoria de continuitate a proiectului: [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md).
