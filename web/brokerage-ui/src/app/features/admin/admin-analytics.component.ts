import { Component, computed, input, output, signal } from '@angular/core';
import { CurrencyPipe, DecimalPipe } from '@angular/common';
import { AdminAnalytics } from '../../core/models';

@Component({
  selector: 'app-admin-analytics',
  imports: [CurrencyPipe, DecimalPipe],
  styleUrl: './admin-analytics.component.scss',
  templateUrl: './admin-analytics.component.html',
})
export class AdminAnalyticsComponent {
  data = input<AdminAnalytics | null>(null);
  periodChange = output<number>();
  selectedPeriod = signal(30);
  readonly periods = [
    { value: 7, label: '7 zile' },
    { value: 30, label: '30 zile' },
    { value: 90, label: '3 luni' },
    { value: 365, label: '12 luni' },
  ];
  values = computed(() => this.data()?.trend.map((item) => item.value) ?? []);
  rawMax = computed(() => {
    const values = this.values();
    return values.length ? Math.max(...values) : 1;
  });
  rawMin = computed(() => {
    const values = this.values();
    return values.length ? Math.min(...values) : 0;
  });
  valueRange = computed(() => Math.max(this.rawMax() - this.rawMin(), this.rawMax() * 0.01, 1));
  maxValue = computed(() => this.rawMax() + this.valueRange() * 0.12);
  minValue = computed(() => Math.max(0, this.rawMin() - this.valueRange() * 0.12));
  chartPoints = computed(() => {
    const points = this.data()?.trend ?? [];
    const range = Math.max(this.maxValue() - this.minValue(), 1);
    return points.map((item, index) => ({
      ...item,
      x: points.length === 1 ? 500 : (index / (points.length - 1)) * 1000,
      y: 238 - ((item.value - this.minValue()) / range) * 210,
    }));
  });
  points = computed(() =>
    this.chartPoints()
      .map((item) => `${item.x},${item.y}`)
      .join(' '),
  );
  areaPath = computed(() => {
    const p = this.chartPoints();
    return p.length
      ? `M ${p[0].x} 250 L ${p.map((x) => `${x.x} ${x.y}`).join(' L ')} L ${p[p.length - 1].x} 250 Z`
      : '';
  });
  firstDate = computed(() => this.data()?.trend[0]?.date ?? '—');
  lastDate = computed(() => this.data()?.trend.at(-1)?.date ?? '—');
  lastValue = computed(() => this.data()?.trend.at(-1)?.value ?? 0);
  change = computed(() => {
    const values = this.values();
    return values.length > 1 && values[0] !== 0
      ? ((values.at(-1)! - values[0]) / values[0]) * 100
      : 0;
  });
  choosePeriod(days: number) {
    this.selectedPeriod.set(days);
    this.periodChange.emit(days);
  }
}
