import { Component, computed, inject, input } from '@angular/core';
import { DomSanitizer, SafeResourceUrl } from '@angular/platform-browser';

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
  private readonly sanitizer = inject(DomSanitizer);

  readonly embedUrl = computed<SafeResourceUrl | null>(() => {
    const url = this.reportUrl().trim();
    if (!url || !this.isPowerBiUrl(url)) return null;
    return this.sanitizer.bypassSecurityTrustResourceUrl(url);
  });

  readonly pages: PowerBiReportPage[] = [
    {
      title: 'Prezentare generală',
      description: 'Indicatorii principali ai platformei',
      metrics: 'Portofolii, tranzacții, comisioane și clienți activi',
    },
    {
      title: 'Portofolii și numerar',
      description: 'Valoare, lichidități și fluxuri valutare',
      metrics: 'Valoare investită, poziții, numerar, depuneri și retrageri',
    },
    {
      title: 'Trading și execuții',
      description: 'Ordine și activitate de tranzacționare',
      metrics: 'Volume, execuții, comisioane și stări ale ordinelor',
    },
    {
      title: 'Ordine avansate',
      description: 'Monitorizare STOP și STOP-LIMIT',
      metrics: 'Declanșări, expirări, volume și ordine neexecutate',
    },
    {
      title: 'KYC și operațiuni',
      description: 'Verificarea identității clienților',
      metrics: 'Stări KYC, soluționări, respingeri și clienți blocați',
    },
    {
      title: 'Audit operațional',
      description: 'Trasabilitatea activității platformei',
      metrics: 'Conectări, modificări acces, estimări și activitate ordine',
    },
  ];

  openReport(): void {
    window.open(this.reportUrl(), '_blank', 'noopener,noreferrer');
  }

  private isPowerBiUrl(url: string): boolean {
    try {
      const parsed = new URL(url);
      return parsed.protocol === 'https:' && parsed.hostname === 'app.powerbi.com';
    } catch {
      return false;
    }
  }
}
