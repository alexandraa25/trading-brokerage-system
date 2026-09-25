import { Component, input } from '@angular/core';
import { DatePipe, DecimalPipe } from '@angular/common';
import { BrokerExecution } from '../../../core/models/admin.models';
@Component({
  selector: 'app-broker-executions',
  imports: [DatePipe, DecimalPipe],
  styleUrl: './broker-executions.component.scss',
  templateUrl: './broker-executions.component.html',
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
