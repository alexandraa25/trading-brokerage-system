import { Component, input } from '@angular/core';

export type PowerBiReportPage = {
  title: string;
  description: string;
  metrics: string;
};

@Component({
  selector: 'app-admin-powerbi',
  styleUrl: './admin-powerbi.component.scss',
  template: `
    <section class="powerbi-hero">
      <div>
        <p>ANALIZĂ AVANSATĂ</p>
        <h2>Rapoarte Power BI</h2>
        <span>Analize interactive construite pe depozitul de date BrokerageDW.</span>
      </div>
      @if (reportUrl()) {
        <button type="button" (click)="openReport()">Deschide raportul Power BI ↗</button>
      }
    </section>

    @if (!reportUrl()) {
      <section class="configuration-card">
        <b>RAPORT NECONFIGURAT</b>
        <h3>Conectează raportul Power BI</h3>
        <p>După publicarea raportului în Power BI Service, copiază URL-ul de embed în <code>core/config/powerbi.config.ts</code>.</p>
        <ol>
          <li>Publică fișierul <code>BrokerageAnalytics.pbix</code> în Power BI Service.</li>
          <li>Deschide raportul și copiază adresa din „Embed report” sau „Secure embed”.</li>
          <li>Lipește adresa în câmpul <code>reportUrl</code>.</li>
        </ol>
      </section>
    }

    <section class="report-grid">
      @for (page of pages; track page.title) {
        <article>
          <span class="report-icon">◔</span>
          <p>{{ page.title }}</p>
          <h3>{{ page.description }}</h3>
          <small>{{ page.metrics }}</small>
        </article>
      }
    </section>

    <section class="card data-note">
      <b>SURSA DATELOR</b>
      <p>BrokerageDB → Staging → BrokerageDW → Power BI. Valorile financiare agregate sunt raportate în EUR, folosind cursurile BCE istorice.</p>
    </section>
  `,
})
export class AdminPowerBiComponent {
  readonly reportUrl = input('');
  readonly pages: PowerBiReportPage[] = [
    { title: 'Overview', description: 'Imagine generală a platformei', metrics: 'Portofolii, tranzacții, comisioane și clienți activi' },
    { title: 'Trading Analysis', description: 'Execuții, instrumente și piețe', metrics: 'BUY/SELL, volum EUR, comisioane și evoluție în timp' },
    { title: 'Customer Analysis', description: 'Clienți, conturi și activitate', metrics: 'Top clienți, conturi și instrumente tranzacționate' },
    { title: 'Portfolio Performance', description: 'Valoare și performanță', metrics: 'Valoare curentă, profit/pierdere și evoluție zilnică' },
    { title: 'Cash & Currency', description: 'Numerar și cursuri BCE', metrics: 'Depuneri, retrageri, conversii și flux net EUR' },
    { title: 'Operational & KYC', description: 'Monitorizare administrativă', metrics: 'Ordine, dosare KYC, timp de soluționare și alerte' },
  ];

  openReport(): void {
    window.open(this.reportUrl(), '_blank', 'noopener,noreferrer');
  }
}
