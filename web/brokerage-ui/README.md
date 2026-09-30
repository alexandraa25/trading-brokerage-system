# Interfața Angular

Interfața Angular 20 oferă ecrane separate pentru client, broker și administrator. Componentele au fișiere `.ts`, `.html` și `.scss` separate și sunt încărcate lazy pentru zonele principale.

## Pornire

```powershell
npm install
npm start
```

Interfața locală rulează la `http://localhost:4200` și comunică cu API-ul la `https://localhost:7103/api`.

În Docker, interfața este servită de Nginx tot la `http://localhost:4200`. Cererile către `/api` sunt redirecționate intern către containerul API. În dezvoltare, același traseu `/api` este redirecționat către API-ul local prin `proxy.conf.json`.

## Ecrane

- **Client:** prezentare portofoliu, instrumente, tranzacționare, numerar, ordine, notificări și profil;
- **Broker:** prezentare, ordine active, ordine STOP, execuții, cursuri valutare și profil;
- **Administrator:** monitorizare, KYC, clienți, conturi, utilizatori, jurnal audit, Power BI și Asistent AI.

## Integrare Power BI

Raportul este păstrat și prezentat local din Power BI Desktop în etapa curentă. Tabul **Power BI** din panoul administratorului este pregătit pentru integrare directă atunci când există un cont Microsoft de serviciu sau instituțional. După publicarea raportului în Power BI Service, copiază URL-ul din **Secure embed** în [powerbi.config.ts](src/app/core/config/powerbi.config.ts), la `reportUrl`. URL-ul trebuie să înceapă cu `https://app.powerbi.com/`; nu introduce tokenuri, parole sau chei API în proiect. Conturile Gmail personale nu pot publica în Power BI Service.

Jurnalul administratorului include subtaburi pentru modificările KYC și activitatea ordinelor. Toate listele operaționale au filtre și paginare; exportul CSV este disponibil în zonele administrative și broker.

## Comenzi

```powershell
npm start        # server de dezvoltare
npm run build    # build de producție
npm run test:ci  # teste automate headless
```

## Securitate în interfață

Tokenul JWT este păstrat local pentru sesiunea curentă. Interfața avertizează cu cinci minute înainte de expirare și deconectează automat utilizatorul la expirare. API-ul invalidează tokenul și dacă administratorul deconectează toate sesiunile unui utilizator.
