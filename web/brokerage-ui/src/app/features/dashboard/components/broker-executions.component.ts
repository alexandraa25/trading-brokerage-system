import { Component, input } from '@angular/core';
import { DatePipe, DecimalPipe } from '@angular/common';

export type BrokerExecution = {
  executionId: number;
  orderId: number;
  symbol: string;
  side: string;
  executedQuantity: number;
  executionPrice: number;
  tradeCurrency: string;
  commissionReporting: number;
  exchangeRateToReporting: number;
  exchangeRateDate: string;
  tradeValueReporting: number;
  executedAt: string;
};

@Component({
  selector: 'app-broker-executions',
  imports: [DatePipe, DecimalPipe],
  styleUrl: './broker-executions.component.scss',
  template: `<section class="card">
    <p>ISTORIC BROKER</p>
    <h2>Execuții recente</h2>
    <table>
      <thead>
        <tr>
          <th>Instrument</th>
          <th>Cantitate</th>
          <th>Preț</th>
          <th>Comision {{ currency() }}</th>
          <th>Curs BCE</th>
          <th>Valoare {{ currency() }}</th>
        </tr>
      </thead>
      <tbody>
        @for (e of paged(); track e.executionId) {
          <tr>
            <td>
              <b>{{ e.symbol }}</b
              ><br /><small>{{ e.executedAt | date: 'dd MMM HH:mm' }}</small>
            </td>
            <td>{{ e.executedQuantity }}</td>
            <td>{{ e.executionPrice | number: '1.2-4' }} {{ e.tradeCurrency }}</td>
            <td>{{ e.commissionReporting * multiplier() | number: '1.2-2' }}</td>
            <td>{{ e.exchangeRateToReporting | number: '1.2-4' }}</td>
            <td>{{ e.tradeValueReporting * multiplier() | number: '1.2-2' }}</td>
          </tr>
        }
      </tbody>
    </table>
    <div class="pagination">
      <button [disabled]="page === 0" (click)="page = page - 1">‹ Anterior</button
      ><span>Pagina {{ page + 1 }} din {{ pages() }}</span
      ><button [disabled]="page + 1 >= pages()" (click)="page = page + 1">Următor ›</button>
    </div>
  </section>`,
})
export class BrokerExecutionsComponent {
  readonly executions = input<BrokerExecution[]>([]);
  readonly currency = input('EUR');
  readonly multiplier = input(1);
  page = 0;
  size = 10;
  pages() {
    return Math.max(1, Math.ceil(this.executions().length / this.size));
  }
  paged() {
    return this.executions().slice(this.page * this.size, (this.page + 1) * this.size);
  }
}
