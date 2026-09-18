# Analiza performanței

## Obiectiv

Analiza măsoară efectul indecșilor asupra interogărilor folosite frecvent. Testele au folosit peste 100.000 de ordine și au urmărit citirile logice, timpul procesorului, durata și operatorii planului de execuție.

```sql
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
```

## Testul 1: cont și dată

Indexul `IX_Order_AccountId_CreatedAt` sprijină filtrarea după cont și ordonarea după data creării.

## Testul 2: cont, stare și dată

```sql
SELECT OrderId, AccountId, InstrumentId, Side, Quantity, Status, CreatedAt
FROM trading.[Order]
WHERE AccountId = 6
  AND Status = 'Pending'
ORDER BY CreatedAt DESC;
```

Înainte de index, interogarea a produs aproximativ 1.064 de citiri logice și a folosit o scanare. După adăugarea `IX_Order_AccountId_Status_CreatedAt`, citirile au scăzut la aproximativ 700, iar planul a folosit `Index Seek`. Reducerea observată a fost de aproximativ 34%.

## Testul 3: instrument și stare

Indexul compus dedicat a produs aproximativ 203 citiri logice pentru `Order`, două citiri pentru `Instrument` și un operator `Index Seek`.

## Testul 4: numai stare

Înainte de index, interogarea a produs aproximativ 1.064 de citiri logice și un `Index Scan`. După adăugarea `IX_Order_Status_CreatedAt`, citirile au scăzut la aproximativ 706, iar planul a folosit `Index Seek`, o reducere de aproximativ 33,6%.

## Costul scrierilor

Indecșii accelerează citirile, dar măresc spațiul ocupat și costul operațiilor `INSERT`, `UPDATE` și `DELETE`. Pentru lotul testat s-au observat aproximativ 172 ms timp de procesor și 227 ms durată totală.

## Strategie de indexare

- Selectivitatea indexului contează.
- Ordinea coloanelor dintr-un index compus trebuie să urmeze predicatele reale.
- Coloanele incluse pot evita accesări suplimentare ale tabelului.
- Un index trebuie justificat de un tipar de acces măsurabil.
- Recomandările automate trebuie analizate, nu aplicate mecanic.
- Planul și citirile logice trebuie comparate înainte și după schimbare.

## Concluzie

Indecșii proiectați pentru filtrele și ordonările reale au redus citirile logice și au transformat scanările în căutări. Câștigul trebuie evaluat împreună cu impactul asupra scrierilor și spațiului de stocare.
