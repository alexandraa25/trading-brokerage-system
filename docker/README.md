# Docker

Configurația Docker pornește aplicația completă pentru demonstrații locale:

```text
Angular + Nginx → ASP.NET Core API → SQL Server
                                     ├─ BrokerageDB
                                     └─ BrokerageDW
```

La prima pornire, serviciul `db-init` creează bazele de date, încarcă datele de bază pentru demonstrație, construiește staging-ul și depozitul de date. Scripturile demonstrative care execută fluxuri de ordine rămân separate, pentru ca inițializarea să fie repetabilă.

## Cerințe

- Docker Desktop pornit, cu containere Linux active;
- minim 4 GB memorie alocată Docker;
- porturile `1433`, `4200` și `8080` disponibile.

## Pornire

Din rădăcina proiectului:

```powershell
Copy-Item .env.example .env
docker-compose up --build
```

Prima pornire poate dura câteva minute, deoarece sunt descărcate imaginile și sunt rulate scripturile SQL. Urmărește inițializarea cu:

```powershell
docker-compose logs -f db-init
```

După mesajul de finalizare, deschide:

- aplicația: `http://localhost:4200`;
- Swagger: `http://localhost:8080/swagger`;
- SQL Server: `localhost,1433`.

Conturile demonstrative sunt în [README-ul principal](../README.md#conturi-demonstrative).

## Reîmprospătare și oprire

```powershell
docker-compose up -d
docker-compose down
```

Datele SQL sunt păstrate în volumul `brokerage-sql-data`. Pentru a recrea complet datele demonstrative, oprește containerele și șterge volumul:

```powershell
docker-compose down -v
```

Această comandă șterge bazele de date Docker existente.

## Power BI

În Power BI Desktop, conectează-te la SQL Server cu:

```text
Server: localhost,1433
Database: BrokerageDW
Authentication: Database
User: sa
Password: valoarea MSSQL_SA_PASSWORD din .env
```

Raportul `.pbix` rămâne local. Consultă [documentația Power BI](../powerbi/README.md).
