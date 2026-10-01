# Analiza performanței

## Obiectiv

Aplicația are peste 100.000 de ordine demonstrative, deci listele și rapoartele trebuie să rămână rapide fără a încărca inutil baza operațională.

## Reguli aplicate în API

- Citirile care nu modifică date folosesc `AsNoTracking()`.
- Listele mari au filtre, sortare și paginare în API; interfața cere doar pagina curentă.
- Endpoint-urile normale folosesc Entity Framework Core și proiecții DTO.
- Operațiile financiare păstrează procedurile SQL și tranzacțiile, deoarece actualizează solduri, poziții și audit în mod atomic.
- Rapoartele Power BI citesc view-uri din `BrokerageDW`, nu tabele din `BrokerageDB`.

## Indecși verificați

### Ordine după cont și dată

`IX_Order_AccountId_CreatedAt` ajută filtrarea după cont și ordonarea descrescătoare după data creării.

### Ordine după cont, stare și dată

```sql
SELECT OrderId, AccountId, InstrumentId, Side, Quantity, Status, CreatedAt
FROM trading.[Order]
WHERE AccountId = 6
  AND Status = 'Pending'
ORDER BY CreatedAt DESC;
```

`IX_Order_AccountId_Status_CreatedAt` a redus citirile logice observate de la aproximativ 1.064 la 700 și a permis `Index Seek` în loc de scanare.

### Ordine după instrument și stare

Indexul compus dedicat susține brokerul, alertele și procesarea ordinelor STOP. Un index separat pe stare și dată sprijină listele de ordine active și rapoartele operaționale.

## Cum se măsoară

```sql
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
```

Se compară citirile logice, durata, timpul CPU și planul de execuție înainte și după adăugarea unui index. Un index este păstrat doar dacă sprijină o interogare reală și oferă un câștig măsurabil.

## Costul scrierilor

Indecșii accelerează citirile, însă măresc spațiul și costul `INSERT`, `UPDATE` și `DELETE`. Nu trebuie adăugați pentru fiecare coloană; sunt aleși după filtrele și sortările folosite de client, broker, administrator și ETL.

## Depozit de date

Query-urile analitice, agregările pe perioade și graficele nu rulează pe OLTP. Ele sunt mutate în `BrokerageDW`, unde modelul stea și view-urile Power BI reduc complexitatea și protejează performanța aplicației operaționale.
