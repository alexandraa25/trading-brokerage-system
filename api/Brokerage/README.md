# API Brokerage

API-ul ASP.NET Core gestionează autentificarea, conturile, numerarul, ordinele,
execuțiile, KYC-ul și operațiunile administrative ale platformei. Este folosit de
interfața Angular și citește/scrie în baza operațională `BrokerageDB`.

## Pornire locală

Cerințe:

- .NET SDK 10;
- SQL Server cu `BrokerageDB` configurată;
- cheia JWT configurată local.

Din directorul `api/Brokerage/Brokerage`:

```powershell
dotnet user-secrets set "Jwt:Key" "o-cheie-locala-lunga-si-secreta"
dotnet run
```

API-ul pornește implicit la `https://localhost:7103`.

## Swagger

În mediul Development, documentația interactivă este disponibilă la:

```text
https://localhost:7103/swagger
```

Pentru endpointurile protejate, autentifică-te prin `POST /api/auth/login`, apoi
folosește tokenul primit în butonul **Authorize** din Swagger, cu formatul:

```text
Bearer TOKEN_JWT
```

## Autentificare și roluri

Autentificarea folosește JWT. Rolurile disponibile sunt:

| Rol | Responsabilități principale |
| --- | --- |
| Customer | Conturi proprii, numerar, conversii, ordine, portofoliu, profil și notificări |
| Broker | Ordine active, execuții, respingeri, istoric și alerte broker |
| Administrator | KYC, clienți, conturi, utilizatori, audit și rapoarte analitice |

## Endpointuri principale

### Public și autentificare

| Metodă | Rută | Scop |
| --- | --- | --- |
| POST | `/api/auth/login` | Autentificare și generare JWT |
| GET | `/api/auth/me` | Identitatea și rolul utilizatorului curent |
| POST | `/api/registration` | Înregistrare client |
| GET | `/api/health` | Starea API |
| GET | `/api/health/database` | Conectivitatea bazei operaționale |

### Client

| Zonă | Rute importante |
| --- | --- |
| Conturi și portofoliu | `GET /api/accounts`, `GET /api/accounts/{id}/cash`, `GET /api/accounts/{id}/portfolio`, `GET /api/accounts/{id}/valuation`, `GET /api/accounts/history` |
| Numerar | depunere, retragere, conversie și istoric în `/api/cash-accounts/*` |
| Ordine | `GET/POST /api/orders`, anulare și istoric execuții |
| Date afișare | `/api/instruments`, `/api/exchange-rates/display`, `/api/profile` |
| Notificări | `/api/notifications/*` |

Operațiunile de numerar și ordine păstrează informația istorică necesară,
inclusiv cursurile BCE pentru valorile de raportare în EUR.

`POST /api/customer-ai/ask` oferă explicații despre portofoliul clientului și
impactul cursurilor BCE. Endpointul citește automat numai conturile asociate
identității JWT curente; nu acceptă un identificator de client în cerere.

### Broker

| Metodă | Rută | Scop |
| --- | --- | --- |
| GET | `/api/broker/orders/history` | Istoric ordine |
| GET | `/api/broker/orders/{id}/details` | Context pentru execuție sau respingere |
| POST | `/api/orders/{id}/executions` | Execuție totală sau parțială |
| POST | `/api/broker/orders/{id}/reject` | Respingere cu motiv |
| GET | `/api/broker/executions` | Istoric execuții |
| GET/POST | `/api/broker/notifications/*` | Alerte broker |

### Administrator

| Zonă | Rute importante |
| --- | --- |
| KYC | `/api/admin/kyc`, audit KYC și actualizare stare |
| Clienți | `/api/admin/customers`, detalii și schimbare stare |
| Conturi | `/api/admin/accounts`, suspendare/reactivare și conturi de numerar |
| Acces | `/api/admin/users`, activare, resetare parolă și audit acces |
| Analiză | `/api/admin/overview`, `/api/admin/analytics` |
| Asistent AI | `POST /api/admin/ai/ask` |

`GET /api/admin/analytics` citește agregări read-only din `BrokerageDW`, folosite
și de tabul Rapoarte din interfața Angular.

## Asistent AI pentru administrator

Tabul **Asistent AI** este disponibil numai administratorilor. El trimite către
serviciul AI doar indicatori agregați din `BrokerageDW`: valoarea totală a
portofoliilor, fluxurile de numerar, comisioanele, ordinele și situația KYC.
Nu transmite din interfață date personale ale clienților și nu execută operații
în aplicație.

Asistentul folosește Groq, cu modelul gratuit `openai/gpt-oss-20b`. Configurează
cheia numai local, în User Secrets, din directorul
`api/Brokerage/Brokerage`:

```powershell
dotnet user-secrets set "Groq:ApiKey" "CHEIA_TA_GROQ"
dotnet user-secrets set "Groq:Model" "openai/gpt-oss-20b"
```

După configurare, repornește API-ul. Cheia nu se salvează în `appsettings.json`,
în codul Angular sau în Git.

## Organizare cod

```text
Brokerage/
├── Controllers/   # endpointuri HTTP pe domenii
├── Data/          # DbContext Entity Framework Core
├── DTOs/          # cereri și răspunsuri API
├── Models/        # entități operaționale
├── Services/      # autentificare, seed și notificări
└── Program.cs     # configurare aplicație, JWT, CORS și Swagger
```

## Configurare

`appsettings.json` conține numai conexiunile locale la `BrokerageDB` și
`BrokerageDW`. Cheia JWT nu se salvează în Git; este citită din User Secrets prin
`Jwt:Key`.

CORS permite interfața Angular locală la `http://localhost:4200` și
`https://localhost:4200`.

## Teste automate API

Proiectul [Brokerage.Api.Tests](Brokerage.Api.Tests) pornește API-ul cu SQLite
temporar și date proprii. Nu modifică `BrokerageDB`.

Din `api/Brokerage` rulează:

```powershell
dotnet test Brokerage.Api.Tests/Brokerage.Api.Tests.csproj
```

Sunt verificate autentificarea, rolurile, accesul interzis, protecția conturilor
clientului, validarea ordinelor, accesul brokerului la execuții și accesul
administratorului la KYC și utilizatori.

Fluxurile care apelează proceduri stocate SQL Server — depunere, retragere,
conversie și execuție efectivă — vor avea o suită SQL Server de test separată.
Aceasta nu trebuie rulată pe `BrokerageDB` principală.
