import { Component, input } from '@angular/core';

export type PowerBiReportPage = {
  title: string;
  description: string;
  metrics: string;
};

@Component({
  selector: 'app-admin-powerbi',
  styleUrl: './admin-powerbi.component.scss',
  templateUrl: './admin-powerbi.component.html',
})
export class AdminPowerBiComponent {
  readonly reportUrl = input('');
  readonly pages: PowerBiReportPage[] = [
    {
      title: 'Overview',
      description: 'Imagine generală a platformei',
      metrics: 'Portofolii, tranzacții, comisioane și clienți activi',
    },
    {
      title: 'Trading Analysis',
      description: 'Execuții, instrumente și piețe',
      metrics: 'BUY/SELL, volum EUR, comisioane și evoluție în timp',
    },
    {
      title: 'Customer Analysis',
      description: 'Clienți, conturi și activitate',
      metrics: 'Top clienți, conturi și instrumente tranzacționate',
    },
    {
      title: 'Portfolio Performance',
      description: 'Valoare și performanță',
      metrics: 'Valoare curentă, profit/pierdere și evoluție zilnică',
    },
    {
      title: 'Cash & Currency',
      description: 'Numerar și cursuri BCE',
      metrics: 'Depuneri, retrageri, conversii și flux net EUR',
    },
    {
      title: 'Operational & KYC',
      description: 'Monitorizare administrativă',
      metrics: 'Ordine, dosare KYC, timp de soluționare și alerte',
    },
  ];

  openReport(): void {
    window.open(this.reportUrl(), '_blank', 'noopener,noreferrer');
  }
}
