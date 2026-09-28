# Structura interfeței Angular

```text
src/app/
├── core/                    # ApiService, modele și fațade de încărcare
├── features/login/          # autentificare
├── features/dashboard/      # ecrane client și broker
│   ├── portfolio/           # valoare, poziții, grafic, favorite
│   ├── cash/                # solduri, depuneri, retrageri, conversii
│   ├── trading/             # instrumente, ordine și istoric
│   ├── broker/              # ordine, execuții, alerte, profil broker
│   └── profile/             # profil client, KYC și sesiuni
├── features/admin/          # KYC, clienți, conturi, personal și audit
└── shared/components/       # notificări și componente reutilizabile
```

`app.ts` coordonează autentificarea, sesiunea, taburile și semnalele de stare. Încărcarea datelor pe rol este delegată către `CustomerDashboardService`, `BrokerDashboardService` și `AdminDashboardService`.

În `features/admin/`, `admin-audit-workspace.component` grupează auditul KYC și auditul ordinelor. Pentru o funcție nouă, adaugă modelele în `core/models`, apelurile HTTP în `core/api.service.ts` și o componentă cu fișiere `.ts`, `.html` și `.scss` în domeniul corespunzător.
