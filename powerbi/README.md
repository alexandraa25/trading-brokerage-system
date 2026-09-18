# Power BI

Directorul conține documentația și capturile raportului. Fișierul editabil `.pbix` nu este versionat, deoarece `.gitignore` exclude fișierele binare Power BI.

## Prezentarea portofoliului

- valoarea totală a portofoliului;
- soldul de numerar;
- pozițiile și numărul de instrumente.

## Activitatea de tranzacționare

- ordine după stare, sens și instrument;
- execuții în timp și volum tranzacționat;
- preț mediu ponderat.

## Activitatea clienților

- clienți activi;
- ordine și volum pe client;
- detaliere client, cont și instrument.

## Risc și operațiuni

- ordine respinse sau anulate;
- execuții eșuate;
- venituri din comisioane și excepții operaționale.

Modelul Power BI consumă datele din `BrokerageDW`, evitând interogarea directă a tabelelor operaționale.
