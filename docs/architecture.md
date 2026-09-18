# Arhitectura sistemului

## Prezentare generală

Sistemul este împărțit în patru straturi:

1. baza operațională `BrokerageDB`;
2. schema intermediară `staging` și procesele ETL;
3. depozitul analitic `BrokerageDW`;
4. raportarea Power BI.

```text
Utilizator / broker
        │
        ▼
BrokerageDB
  core | trading | audit
        │
        ▼
staging + ETL
        │
        ▼
BrokerageDW
        │
        ▼
Power BI
```

## Stratul operațional

Schema `core` gestionează clientul, verificarea KYC, contul de tranzacționare și conturile de numerar. Schema `trading` gestionează piețele, emitenții, instrumentele, ordinele, execuțiile, pozițiile, comisioanele și tranzacțiile de numerar. Schema `audit` păstrează istoricul schimbărilor.

Un ordin reprezintă intenția clientului. O execuție reprezintă o cantitate tranzacționată efectiv. Separarea permite execuții parțiale și calculul corect al prețului mediu ponderat.

Procedurile `usp_CreateOrder`, `usp_DepositCash` și `usp_ExecuteOrder` concentrează regulile de business. Operațiile financiare rulează în tranzacții și folosesc blocări explicite pentru a evita execuțiile duble și consumarea concurentă a aceluiași sold sau aceleiași poziții.

## Stratul ETL

Datele sunt copiate mai întâi în schema `staging`. Încărcarea inițială este completă, iar încărcările următoare folosesc marcaje temporale și o limită superioară fixată la începutul rulării.

Entitățile modificabile folosesc actualizare și inserare. `Execution` și `CashTransaction` folosesc numai inserare și verifică identificatorul sursă pentru a preveni duplicatele.

Jurnalul ETL înregistrează starea și numărul de rânduri procesate. Marcajele sunt actualizate în aceeași tranzacție cu datele, astfel încât un eșec nu poate marca drept procesate date care nu au fost încărcate.

## Depozitul de date

Modelul este o schemă stea cu `FactTrade` în centru și dimensiunile `DimDate`, `DimCustomer`, `DimAccount` și `DimInstrument` în jurul său.

Granularitatea tabelului de fapte este o execuție. Cheile surogat separă modelul analitic de identificatorii operaționali și permit extinderea ulterioară către dimensiuni cu istoric.

## Raportare

Power BI se conectează la depozitul de date, nu direct la tabelele tranzacționale. Separarea reduce încărcarea sistemului OLTP și simplifică interogările analitice.
