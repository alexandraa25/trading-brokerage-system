import { Component, computed, input, output, signal } from '@angular/core';
import { DatePipe, DecimalPipe } from '@angular/common';
import { PortfolioHistoryPoint } from '../../../core/models';

type PeriodRequest = { from: string; to: string };

@Component({
  selector: 'app-portfolio-chart',
  imports: [DatePipe, DecimalPipe],
  styleUrl: './portfolio-chart.component.scss',
  templateUrl: './portfolio-chart.component.html',
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
