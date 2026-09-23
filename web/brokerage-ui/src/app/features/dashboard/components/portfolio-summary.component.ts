import { Component, input } from '@angular/core';
import { DecimalPipe } from '@angular/common';
@Component({
  selector: 'app-portfolio-summary',
  imports: [DecimalPipe],
  template: `<div class="summary">
    <article>
      <span>Valoare portofoliu</span
      ><strong>{{ total() | number: '1.2-2' }} {{ currency() }}</strong
      ><small>cotații simulate + BCE</small>
    </article>
    <article>
      <span>Investit inițial</span
      ><strong>{{ invested() | number: '1.2-2' }} {{ currency() }}</strong>
    </article>
    <article>
      <span>Profit / pierdere</span
      ><strong [class.positive]="profit() >= 0" [class.negative]="profit() < 0"
        >{{ profit() | number: '1.2-2' }} {{ currency() }}</strong
      ><small>{{ percent() | number: '1.2-2' }}%</small>
    </article>
  </div>`,
  styleUrl: './portfolio-summary.component.scss',
})
export class PortfolioSummaryComponent {
  accounts = input(0);
  positions = input(0);
  total = input(0);
  invested = input(0);
  profit = input(0);
  percent = input(0);
  currency = input('EUR');
}
