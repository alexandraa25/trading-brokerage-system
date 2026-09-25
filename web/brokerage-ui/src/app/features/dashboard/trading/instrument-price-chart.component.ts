import { Component, computed, input, output } from '@angular/core';
import { DecimalPipe } from '@angular/common';
import { Instrument, InstrumentQuotePoint } from '../../../core/models';

@Component({
  selector: 'app-instrument-price-chart',
  imports: [DecimalPipe],
  styleUrl: './instrument-price-chart.component.scss',
  templateUrl: './instrument-price-chart.component.html',
})
export class InstrumentPriceChartComponent {
  instrument = input<Instrument | null>(null);
  points = input<InstrumentQuotePoint[]>([]);
  closed = output<void>();
  periodChange = output<number>();
  values = computed(() => this.points().map((x) => x.marketPrice));
  rawMin = computed(() => (this.values().length ? Math.min(...this.values()) : 0));
  rawMax = computed(() => (this.values().length ? Math.max(...this.values()) : 1));
  padding = computed(() =>
    Math.max((this.rawMax() - this.rawMin()) * 0.12, this.rawMax() * 0.01, 0.01),
  );
  min = computed(() => Math.max(0, this.rawMin() - this.padding()));
  max = computed(() => this.rawMax() + this.padding());
  chart = computed(() => {
    const p = this.points(),
      range = Math.max(this.max() - this.min(), 0.01);
    return p.map((x, i) => ({
      ...x,
      x: p.length === 1 ? 500 : (i / (p.length - 1)) * 1000,
      y: 238 - ((x.marketPrice - this.min()) / range) * 210,
    }));
  });
  line = computed(() =>
    this.chart()
      .map((x) => `${x.x},${x.y}`)
      .join(' '),
  );
  area = computed(() => {
    const p = this.chart();
    return p.length
      ? `M ${p[0].x} 250 L ${p.map((x) => `${x.x} ${x.y}`).join(' L ')} L ${p.at(-1)!.x} 250 Z`
      : '';
  });
  change = computed(() =>
    this.values().length > 1
      ? ((this.values().at(-1)! - this.values()[0]) / this.values()[0]) * 100
      : 0,
  );
}
