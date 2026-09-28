# Pagina Power BI — Audit operațional

## Sursă de date

Importă `dw.vwPowerBiOperationalAudit`. Datele reunesc conectările,
modificările de acces și acțiunile asupra ordinelor. Detaliile tehnice despre
dispozitiv și adresă IP nu sunt incluse în raport, pentru a limita expunerea
datelor personale.

## Măsuri DAX

```DAX
Evenimente audit = COUNTROWS ( vwPowerBiOperationalAudit )

Conectări =
CALCULATE ( [Evenimente audit], vwPowerBiOperationalAudit[Sursa] = "Session" )

Acțiuni ordine =
CALCULATE ( [Evenimente audit], vwPowerBiOperationalAudit[Sursa] = "Order" )

Modificări acces =
CALCULATE ( [Evenimente audit], vwPowerBiOperationalAudit[Sursa] = "Access" )

Utilizatori activi în audit =
DISTINCTCOUNT ( vwPowerBiOperationalAudit[Utilizator] )
```

## Aranjare

Pe primul rând: patru carduri pentru `Evenimente audit`, `Conectări`,
`Acțiuni ordine` și `Modificări acces`.

Sub ele, pune un grafic pe zile cu `Evenimente audit`, un grafic cu bare după
`Acțiune` și un grafic inelar după `Sursă`. În partea de jos, adaugă tabelul
cu `Moment`, `Utilizator`, `Rol`, `Sursă`, `Acțiune`, `IdOrdin` și `Detalii`.

Adaugă filtre pentru `Data`, `Rol`, `Utilizator`, `Sursă`, `Acțiune` și
`IdOrdin`.
