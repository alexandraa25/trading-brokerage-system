# API Brokerage

API-ul ASP.NET Core gestionează autentificarea, KYC, conturile, numerarul, ordinele, brokerajul și administrarea platformei. Citește și scrie în `BrokerageDB`; pentru indicatorii administratorului citește agregări din `BrokerageDW`.

## Configurare și pornire

Din `api/Brokerage/Brokerage`:

```powershell
dotnet user-secrets set "Jwt:Key" "o-cheie-locala-lunga-si-secreta"
dotnet run
```

API: `https://localhost:7103` · Swagger: `https://localhost:7103/swagger`.

## Docker

În Docker, API-ul rulează la `http://api:8080` în rețeaua internă și este expus local la `http://localhost:8080`. Conexiunile SQL și cheia JWT sunt configurate prin variabile de mediu în `docker-compose.yml`; nu sunt păstrate în `appsettings.json`. Docker dezactivează redirecționarea HTTPS locală prin `UseHttpsRedirection=false`.

Consultă [ghidul Docker](../../docker/README.md) pentru pornirea tuturor serviciilor.

Pentru AI configurează opțional:

```powershell
dotnet user-secrets set "Groq:ApiKey" "CHEIA_TA_GROQ"
dotnet user-secrets set "Groq:Model" "openai/gpt-oss-20b"
```

## Roluri

| Rol | Acces |
| --- | --- |
| Customer | propriile conturi, numerar, portofoliu, ordine, piață, KYC și profil |
| Broker | ordine active/STOP, execuții, respingeri, alerte și istoric |
| Administrator | KYC, clienți, conturi, personal, sesiuni, audit, monitorizare, Power BI și AI |

## Funcții importante

### Ordine

- `POST /api/orders/estimate` calculează prețul, comisionul de 0,25%, disponibilul și lipsa de fonduri;
- `POST /api/orders` creează MARKET, LIMIT, STOP și STOP-LIMIT;
- `POST /api/orders/{id}/cancel-partial` anulează parțial un ordin activ;
- comenzile pot avea valabilitate `DAY`, `DATE` sau `GTC`;
- `StopOrderActivationService` verifică periodic cotațiile, declanșează ordinele STOP și expiră ordinele ajunse la termen;
- execuția STOP-LIMIT verifică limita indicată de client.

### Securitate și audit

- `POST /api/auth/change-password` schimbă parola utilizatorului curent;
- `GET /api/profile/sessions` afișează autentificările proprii;
- `GET /api/admin/sessions` afișează conectările personalului;
- `POST /api/admin/users/{id}/sign-out-all` invalidează toate tokenurile unui broker sau administrator;
- `GET /api/admin/order-audit` returnează estimările de ordin, anulările parțiale și activările STOP;
- auditul folosește `audit.UserSessionHistory`, `audit.OrderActivityLog` și `audit.AccessAuditLog`.

Rulează obligatoriu `database/22_security_activity_audit.sql` și `database/23_session_revocation.sql` înainte de folosirea acestor funcții.

### Administrator

Administratorul gestionează KYC, clienți, conturi, conturi de numerar, utilizatori și sesiuni. Rutele `GET /api/admin/overview` și `GET /api/admin/analytics` alimentează monitorizarea și graficele din Angular. `POST /api/admin/ai/ask` primește numai indicatori agregați, fără identificatori personali de client.

## Reguli de acces la date

- endpoint-urile operaționale obișnuite folosesc Entity Framework Core și proiecții LINQ;
- citirile de listă folosesc `AsNoTracking()`, filtre, sortare deterministă și paginare server-side (`page`, `pageSize`, maximum 100 elemente);
- depunerile, retragerile, conversiile valutare, crearea/executarea/anularea ordinelor folosesc proceduri SQL, pentru validări și actualizări atomice;
- analiticele administratorului citesc view-urile `dw.vwPowerBi*` din `BrokerageDW`, nu tabelele operaționale;
- SQL direct rămâne rezervat pentru audit, agregări financiare complexe și proceduri stocate.

## Organizare

```text
Brokerage/
├── Controllers/  # endpointuri pe domenii
├── Data/         # DbContext Entity Framework Core
├── DTOs/         # cereri și răspunsuri
├── Models/       # entități operaționale
├── Services/     # autentificare, notificări, audit, STOP și AI
└── Program.cs    # JWT, CORS, Swagger și injectarea serviciilor
```

## Teste

```powershell
cd api\Brokerage
dotnet test Brokerage.Api.Tests/Brokerage.Api.Tests.csproj
```

Testele API folosesc SQLite temporar și nu modifică `BrokerageDB`. Testele SQL Server pentru fluxurile tranzacționale sunt în directorul rădăcină `tests/`.
