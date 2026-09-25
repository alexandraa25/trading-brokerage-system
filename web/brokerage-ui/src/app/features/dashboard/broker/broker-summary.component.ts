import { Component, computed, input } from '@angular/core';
import { DecimalPipe } from '@angular/common';
import { Order } from '../../../core/models';
import { BrokerExecution } from '../../../core/models/admin.models';

@Component({
  selector: 'app-broker-summary',
  imports: [DecimalPipe],
  styleUrl: './broker-summary.component.scss',
  templateUrl: './broker-summary.component.html',
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
