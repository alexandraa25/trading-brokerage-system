import { Component, computed, input } from '@angular/core';
import { DecimalPipe } from '@angular/common';
import { Order } from '../../../core/models';
import { BrokerExecution } from '../../../core/models/admin.models';

@Component({
  selector: 'app-broker-summary',
  imports: [DecimalPipe],
  styleUrl: './broker-summary.component.scss',
  template: `<section class="summary">
      <article>
        <span>Ordine active</span><strong>{{ activeOrders() }}</strong
        ><small>în așteptare sau parțiale</small>
      </article>
      <article>
        <span>Execuții recente</span><strong>{{ executions().length }}</strong
        ><small>înregistrate în istoric</small>
      </article>
      <article>
        <span>Volum executat</span
        ><strong>{{ executedVolume() | number: '1.2-2' }} {{ currency() }}</strong
        ><small>valoare afișată</small>
      </article>
      <article>
        <span>Ordine parțiale</span><strong>{{ partialOrders() }}</strong
        ><small>necesită atenție</small>
      </article>
    </section>
    <section class="queue-card">
      <p>COADĂ BROKER</p>
      <h2>Prioritate operațională</h2>
      <span>
        @if (partialOrders()) {
          Ai {{ partialOrders() }} ordine executate parțial care pot necesita o nouă execuție.
        } @else {
          Nu există ordine executate parțial în acest moment.
        }
      </span>
    </section>`,
})
export class BrokerSummaryComponent {
  readonly orders = input<Order[]>([]);
  readonly executions = input<BrokerExecution[]>([]);
  readonly currency = input('EUR');
  readonly multiplier = input(1);
  readonly activeOrders = computed(
    () =>
      this.orders().filter(
        (item) => item.status === 'Pending' || item.status === 'PartiallyExecuted',
      ).length,
  );
  readonly partialOrders = computed(
    () => this.orders().filter((item) => item.status === 'PartiallyExecuted').length,
  );
  readonly executedVolume = computed(
    () =>
      this.executions().reduce((sum, item) => sum + item.tradeValueReporting, 0) *
      this.multiplier(),
  );
}
