# API Brokerage

Acest director conține API-ul ASP.NET Core care conectează interfața Angular la `BrokerageDB`. API-ul aplică regulile de acces pentru client, broker și administrator, iar regulile tranzacționale critice rămân în procedurile stocate SQL Server.

## Pornire

Cerințe: .NET SDK 10, SQL Server cu `BrokerageDB` instalată și `Jwt:Key` configurată local.

```powershell
cd api\Brokerage
dotnet user-secrets set "Jwt:Key" "o-cheie-locala-lunga-si-secreta" --project Brokerage\Brokerage.csproj
dotnet run --project Brokerage\Brokerage.csproj
```

Swagger este disponibil la `https://localhost:7103/swagger`.

Pentru dezvoltare, rulează înainte scripturile `database/06_api_identity.sql`, `database/22_security_activity_audit.sql` și `database/23_session_revocation.sql`.

## Domenii API

| Domeniu | Exemple de rute |
| --- | --- |
| Autentificare și profil | `/api/auth/*`, `/api/profile/*` |
| Conturi și numerar | `/api/accounts/*`, `/api/cash-accounts/*` |
| Ordine | `/api/orders`, `/api/orders/estimate`, anulări și execuții |
| Piață | `/api/instruments`, `/api/market/*`, `/api/exchange-rates/*` |
| Broker | `/api/broker/orders/*`, `/api/broker/executions`, `/api/broker/notifications/*` |
| Administrator | `/api/admin/kyc`, clienți, conturi, utilizatori, sesiuni și audit |

## Securitate

JWT-ul include rolul și versiunea sesiunii. Administratorul poate invalida toate sesiunile unui membru al personalului prin `POST /api/admin/users/{id}/sign-out-all`; tokenurile emise anterior nu mai sunt acceptate.

Cheile JWT și Groq se configurează doar prin User Secrets. Nu le salva în Git sau în `appsettings.json`.
