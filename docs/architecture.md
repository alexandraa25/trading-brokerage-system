# Arhitectura sistemului

## Prezentare generală

Aplicația este un sistem demonstrativ de trading și brokerage, cu interfață Angular, API ASP.NET Core, bază operațională SQL Server, depozit de date, automatizare ETL și rapoarte Power BI.

```text
Utilizator (client / broker / administrator)
        │
        ▼
Angular + Nginx
        │ /api
        ▼
ASP.NET Core API
        │
        ├── BrokerageDB (OLTP: core, trading, audit)
        ├── cursuri BCE și cotații istorice
        ├── asistent AI configurabil
        │
        ▼
staging + ETL
        │
        ▼
BrokerageDW + view-uri Power BI
        │
        ▼
Power BI Desktop / Service
```

Aplicația poate rula local sau în containere Docker: SQL Server, API și interfața web. Nginx livrează Angular și redirecționează apelurile `/api` către API.

## Roluri și interfață

- **Client:** portofoliu în EUR sau într-o monedă selectată, conturi de numerar, depuneri, retrageri, conversii, instrumente, favorite, alerte de preț, ordine și profil.
- **Broker:** ordine active și ordine care necesită atenție, ordine STOP declanșate, execuții, alerte, schimb valutar, export CSV, profil și audit operațional.
- **Administrator:** KYC, clienți, conturi, utilizatori și acces, monitorizare și raportare, audit KYC și ordine, AI și linkuri către rapoarte Power BI.

Fiecare rol primește doar datele și taburile permise de API și interfață.

## Stratul operațional

`BrokerageDB` are schemele `core`, `trading` și `audit`.

- `core` gestionează utilizatori, clienți, KYC, conturi de tranzacționare, conturi de numerar, monede și cursuri BCE.
- `trading` gestionează piețe, emitenți, instrumente, cotații, ordine, execuții, poziții, comisioane, conversii, favorite și alerte de preț.
- `audit` păstrează istoricul stărilor ordinelor, importurile de cursuri, autentificările și evenimentele operaționale.

Endpoint-urile de citire obișnuite folosesc Entity Framework Core. Listele mari sunt citite cu `AsNoTracking()`, filtre, sortare și paginare. Operațiile financiare cu efect asupra soldurilor sau pozițiilor folosesc proceduri SQL și tranzacții: depunere, retragere, conversie, creare, execuție și anulare de ordin.

Ordinele pot fi MARKET, LIMIT, STOP și STOP-LIMIT, cu valabilitate pentru ziua curentă, până la o dată sau GTC. Sunt susținute execuții parțiale, anulări parțiale, estimarea comisionului și validarea fondurilor înainte de confirmare. Execuția salvează cursul BCE folosit, pentru ca rapoartele istorice să poată fi refăcute corect.

## Date de piață și cursuri

Cursurile BCE sunt importate zilnic. Cotațiile instrumentelor sunt păstrate istoric și sunt utilizate pentru evoluția portofoliului, graficele instrumentelor, alertele de preț și activarea ordinelor STOP. Dacă datele sunt vechi, administratorul vede o alertă operațională.

## Securitate și audit

Autentificarea folosește JWT și politici de autorizare pe roluri. Aplicația include schimbarea parolei, expirarea vizibilă a sesiunii, avertizare înainte de deconectare, istoric de autentificări/dispozitive și deconectarea tuturor sesiunilor. Acțiunile administrative și evenimentele importante ale ordinelor sunt auditate.

## ETL, depozit și raportare

Datele sunt încărcate din OLTP în `staging`, apoi în `BrokerageDW`. Depozitul folosește dimensiuni pentru dată, client, cont, instrument și monedă, plus tabele de fapte pentru tranzacții, operațiuni de numerar, KYC, cursuri și evoluția portofoliului.

Power BI consumă view-urile `dw.vwPowerBi*`, nu tabelele tranzacționale. Raportul include prezentare generală, portofoliu și numerar, analiză de tranzacționare, ordine avansate și KYC/operațiuni.
