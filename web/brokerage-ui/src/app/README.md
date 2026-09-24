# Structura interfeței Angular

- `core/` conține serviciile API și modelele comune.
- `core/services/` conține fațadele de încărcare pentru Client, Broker și Administrator.
- `shared/components/` conține componente reutilizabile, precum panoul de notificări.
- `features/login/` gestionează autentificarea.
- `features/dashboard/portfolio/` conține prezentarea portofoliului, conturile, pozițiile și evoluția.
- `features/dashboard/cash/` conține soldurile, depunerile, retragerile, conversiile și istoricul de numerar.
- `features/dashboard/trading/` conține instrumentele, formularul de ordin și istoricul ordinelor.
- `features/dashboard/broker/` conține componentele dedicate rolului Broker.
- `features/dashboard/profile/` conține profilul și informațiile KYC ale clientului.
- `features/admin/` conține panourile administratorului, grupate după responsabilitate: KYC, clienți, conturi, utilizatori, audit și rapoarte.
- `app.ts` coordonează sesiunea, starea ecranului și comunicarea dintre componente; nu conține modele locale.

Pentru o funcție nouă, creează componenta în domeniul potrivit, păstrează modelele reutilizabile în `core/models/`, iar apelurile HTTP de nivel jos în `core/api.service.ts`.
