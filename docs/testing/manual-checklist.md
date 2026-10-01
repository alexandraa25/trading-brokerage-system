# Verificare manuală a aplicației

Folosește lista după o modificare importantă, după import de date sau înainte de demonstrare.

## Client

1. Autentificare, expirare sesiune, schimbare parolă și profil cu istoricul autentificărilor.
2. Deschidere cont de numerar, depunere, retragere și conversie între monede; verifică soldul și cursul BCE reținut.
3. Filtrare portofoliu după moneda reală și schimbarea monedei doar pentru afișare.
4. Favorite, alerte de preț și grafice istorice pentru instrumente.
5. Ordine MARKET, LIMIT, STOP și STOP-LIMIT; estimarea comisionului și verificarea fondurilor înainte de confirmare.
6. Anulare parțială și verificarea cantității comandate, executate, anulate și rămase în istoric.

## Broker

1. Filtre, paginare și reîmprospătare automată pentru ordine active, atenție și ordine STOP declanșate.
2. Execuție sau respingere, inclusiv motivul pentru care un STOP-LIMIT nu se poate executa.
3. Istoric execuții cu cantitate, preț, comision, curs BCE și valoare EUR.
4. Alerte broker, export CSV, selectarea monedei de afișare, conversie și profil.

## Administrator

1. Aprobare/respingere KYC și blocarea automată când KYC este respins.
2. Reactivare după remediere și motiv obligatoriu pentru suspendare/blocare.
3. Căutare, filtre, paginare și detalii pentru clienți și conturi.
4. Creare, activare/dezactivare și resetare parolă pentru brokeri și administratori.
5. Monitorizare: clienți activi, KYC întârziat, ordine active, execuții zilnice, curs BCE/cotații neactualizate.
6. Audit KYC și ordine, filtrare și export CSV.

## Acces și date

1. Clientul nu poate accesa datele unui alt client și nu vede taburile broker/administrator.
2. Brokerul nu poate administra KYC, clienți sau utilizatori.
3. Administratorul nu are ecrane de tranzacționare specifice clientului/brokerului.
4. Rulează fluxul zilnic și confirmă actualizarea cursurilor, cotațiilor, depozitului și raportului Power BI.

## Teste automate

### Angular

Din `web/brokerage-ui`:

```powershell
npm run test:ci
```

### API

Din `api/Brokerage`:

```powershell
dotnet test Brokerage.Api.Tests/Brokerage.Api.Tests.csproj
```

### SQL Server

Scripturile din `tests/` verifică fluxurile financiare, STOP/STOP-LIMIT, comisioane, anulări parțiale și integritatea datelor. Testele de concurență pot necesita două sesiuni SQL Server.
