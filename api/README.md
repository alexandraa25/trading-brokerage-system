# API Brokerage

API-ul ASP.NET Core oferă primul flux pentru client: autentificare, conturi,
solduri, portofoliu și ordine. Utilizează `BrokerageDB` și procedurile SQL
existente pentru regulile de tranzacționare.

## Pornire

Rulați mai întâi `database/06_api_identity.sql` din directorul rădăcină al
proiectului, apoi:

```powershell
cd api\Brokerage
dotnet run --project Brokerage\Brokerage.csproj
```

Cheia JWT locală se configurează o singură dată prin User Secrets:

```powershell
dotnet user-secrets set "Jwt:Key" "o-cheie-lungă-și-aleatoare" --project Brokerage\Brokerage.csproj
```

După pornire, interfața de test Swagger este disponibilă la
`https://localhost:7103/swagger`. Alegeți `POST /api/auth/login`, apăsați
`Try it out`, autentificați-vă, copiați valoarea `token`, apoi apăsați
`Authorize` și introduceți `Bearer <token>`.

În mediul `Development`, aplicația creează numai dacă lipsesc doi utilizatori
demonstrativi:

| Rol | Email | Parolă |
| --- | --- | --- |
| Client | `customer.demo@brokerage.local` | `DemoCustomer!2026` |
| Broker | `broker.demo@brokerage.local` | `DemoBroker!2026` |

În producție, stocați cheia JWT într-un secret de mediu, nu în Git și nu în
`appsettings.json`.

## Endpointuri

| Metodă | Rută | Acces |
| --- | --- | --- |
| `GET` | `/api/health/database` | public |
| `POST` | `/api/auth/login` | public |
| `GET` | `/api/auth/me` | autentificat |
| `GET` | `/api/accounts` | clientul propriu sau personal autorizat |
| `GET` | `/api/accounts/{accountId}/cash` | proprietar sau personal autorizat |
| `GET` | `/api/accounts/{accountId}/portfolio` | proprietar sau personal autorizat |
| `GET` | `/api/instruments` | autentificat |
| `POST` | `/api/cash-accounts/{cashAccountId}/deposits` | proprietar sau personal autorizat |
| `GET` | `/api/cash-accounts/{cashAccountId}/transactions` | proprietar sau personal autorizat |
| `GET` | `/api/orders` | clientul propriu sau personal autorizat |
| `GET` | `/api/orders/{orderId}` | proprietar sau personal autorizat |
| `GET` | `/api/orders/{orderId}/executions` | proprietar sau personal autorizat |
| `POST` | `/api/orders` | proprietar sau personal autorizat |
| `POST` | `/api/orders/{orderId}/cancel` | proprietar sau personal autorizat |
| `POST` | `/api/orders/{orderId}/executions` | broker sau administrator |

Un client nu poate cere datele unui alt client. Crearea ordinului apelează
`trading.usp_CreateOrder`, care validează KYC, starea contului, instrumentul,
numerarul și poziția pentru vânzare.

Depunerile folosesc `trading.usp_DepositCash`. Execuția ordinelor folosește
`trading.usp_ExecuteOrder`, actualizează soldul și poziția, înregistrează
comisionul și păstrează cursul BCE real în EUR utilizat pentru execuție.

## Exemplu login

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "customer.demo@brokerage.local",
  "password": "DemoCustomer!2026"
}
```

Folosiți tokenul primit în antetul `Authorization: Bearer <token>`.
