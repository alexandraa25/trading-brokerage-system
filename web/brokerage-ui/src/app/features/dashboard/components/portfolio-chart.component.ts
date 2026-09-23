import { Component, computed, input, output, signal } from '@angular/core';
import { DatePipe, DecimalPipe } from '@angular/common';
import { PortfolioHistoryPoint } from '../../../core/models';

type PeriodRequest = { from: string; to: string };

@Component({
  selector: 'app-portfolio-chart',
  imports: [DatePipe, DecimalPipe],
  styleUrl: './portfolio-chart.component.scss',
  template: `<section class="card">
    <div class="chart-head">
      <div>
        <p>EVOLUȚIE REALĂ</p>
        <h2>Valoarea portofoliului</h2>
        <span>Capturi zilnice convertite în {{ currency() }}.</span>
      </div>
      @if (latest()) {
        <div class="current">
          <strong>{{ latest()!.totalValueEur | number: '1.2-2' }} {{ currency() }}</strong
          ><small [class.good]="change() >= 0" [class.bad]="change() < 0"
            >{{ change() >= 0 ? '+' : '' }}{{ change() | number: '1.2-2' }} {{ currency() }}</small
          >
        </div>
      }
    </div>
    <div class="periods">
      <button [class.active]="selectedPeriod() === '7'" (click)="selectDays(7, '7')">7 zile</button
      ><button [class.active]="selectedPeriod() === '30'" (click)="selectDays(30, '30')">
        30 zile</button
      ><button [class.active]="selectedPeriod() === '84'" (click)="selectDays(84, '84')">
        12 săptămâni</button
      ><button
        [class.active]="selectedPeriod() === 'custom'"
        (click)="selectedPeriod.set('custom')"
      >
        Perioadă aleasă
      </button>
    </div>
    @if (selectedPeriod() === 'custom') {
      <div class="custom">
        <label
          >De la<input
            type="date"
            [value]="fromDate()"
            (change)="fromDate.set($any($event.target).value)" /></label
        ><label
          >Până la<input
            type="date"
            [value]="toDate()"
            (change)="toDate.set($any($event.target).value)" /></label
        ><button (click)="applyCustom()" [disabled]="!fromDate() || !toDate()">Afișează</button>
      </div>
    }
    @if (points().length > 1) {
      <div class="chart-wrap">
        <svg
          viewBox="0 0 720 270"
          preserveAspectRatio="none"
          role="img"
          aria-label="Evoluția valorii portofoliului"
        >
          <defs>
            <linearGradient id="area" x1="0" x2="0" y1="0" y2="1">
              <stop offset="0%" stop-color="#28b6ae" stop-opacity=".34" />
              <stop offset="100%" stop-color="#28b6ae" stop-opacity="0" />
            </linearGradient>
          </defs>
          <path class="area" [attr.d]="area()" />
          <polyline class="line" [attr.points]="line()" />
          @for (point of graphPoints(); track point.snapshotDate) {
            <circle [attr.cx]="point.x" [attr.cy]="point.y" r="4">
              <title>
                {{ point.snapshotDate | date: 'dd.MM.yyyy' }}:
                {{ point.totalValueEur | number: '1.2-2' }} {{ currency() }}
              </title>
            </circle>
          }
        </svg>
      </div>
      <div class="axis">
        <span>{{ points()[0].snapshotDate | date: 'dd MMM' }}</span
        ><span>{{ points()[points().length - 1].snapshotDate | date: 'dd MMM yyyy' }}</span>
      </div>
    } @else {
      <div class="empty">
        <b>Nu există suficiente capturi pentru acest interval.</b
        ><span>Alege o perioadă mai mare sau revino după următoarea captură zilnică.</span>
      </div>
    }
    <small class="source">Sursă: cotații simulate zilnice și cursuri BCE.</small>
  </section>`,
})
export class PortfolioChartComponent {
  points = input<PortfolioHistoryPoint[]>([]);
  currency = input('EUR');
  periodChange = output<PeriodRequest>();
  selectedPeriod = signal('7');
  fromDate = signal('');
  toDate = signal('');
  latest = computed(() => this.points().at(-1));
  change = computed(() =>
    this.points().length ? this.points().at(-1)!.totalValueEur - this.points()[0].totalValueEur : 0,
  );
  graphPoints = computed(() => {
    const data = this.points();
    const values = data.map((point) => point.totalValueEur);
    const min = Math.min(...values);
    const max = Math.max(...values);
    const span = Math.max(max - min, 1);
    return data.map((point, index) => ({
      ...point,
      x: 28 + index * (664 / Math.max(data.length - 1, 1)),
      y: 222 - ((point.totalValueEur - min) / span) * 170,
    }));
  });
  line = computed(() =>
    this.graphPoints()
      .map((point) => `${point.x.toFixed(1)},${point.y.toFixed(1)}`)
      .join(' '),
  );
  area = computed(() => {
    const points = this.graphPoints();
    return points.length
      ? `M ${points[0].x} 232 L ${this.line().replaceAll(',', ' ')} L ${points.at(-1)!.x} 232 Z`
      : '';
  });
  selectDays(days: number, key: string) {
    this.selectedPeriod.set(key);
    const to = new Date();
    const from = new Date();
    from.setDate(to.getDate() - (days - 1));
    this.periodChange.emit({ from: this.formatDate(from), to: this.formatDate(to) });
  }
  applyCustom() {
    if (this.fromDate() && this.toDate() && this.fromDate() <= this.toDate())
      this.periodChange.emit({ from: this.fromDate(), to: this.toDate() });
  }
  private formatDate(value: Date) {
    return value.toISOString().slice(0, 10);
  }
}
