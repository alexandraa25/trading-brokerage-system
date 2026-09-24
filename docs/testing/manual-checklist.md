# Verificare manuală a aplicației

Folosește aceste verificări după o modificare importantă a interfeței:

1. Client: autentificare, depunere, retragere, conversie și creare ordin.
2. Broker: filtrare ordine, deschidere detalii, execuție și respingere.
3. Administrator: aprobare/respingere KYC, suspendare/reactivare cont și
   gestionare utilizatori.
4. Verifică accesul: un client nu vede datele altui client, iar brokerul și
   administratorul văd numai taburile specifice rolului.
5. După date noi, rulează fluxul zilnic și confirmă apariția lor în Power BI.

Scripturile SQL din `tests/` validează automat integritatea și fluxurile de
bază. Testele de concurență pot necesita două sesiuni SQL Server.


## Teste automate Angular

În web/brokerage-ui, rulează:

``powershell
npm run test:ci
`` 

Sunt verificate filtrele din Clienți și Utilizatori, pop-up-ul pentru client nou și calculul dinamic al punctelor graficului administrativ.

## Teste automate API

Din `api/Brokerage`, rulează:

```powershell
dotnet test Brokerage.Api.Tests/Brokerage.Api.Tests.csproj
```

Testele pornesc un API local cu date temporare și nu modifică baza principală.