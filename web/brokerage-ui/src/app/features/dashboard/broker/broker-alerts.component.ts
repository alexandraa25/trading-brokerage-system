import { Component, input, output } from '@angular/core';
import { BrokerIntelligentAlert } from '../../../core/models/admin.models';

@Component({
  selector: 'app-broker-alerts',
  styleUrl: './broker-alerts.component.scss',
  templateUrl: './broker-alerts.component.html',
})
export class BrokerAlertsComponent {
  readonly alerts = input<BrokerIntelligentAlert[]>([]);
  readonly opened = output<number>();
  readonly pageSize = 5;
  page = 0;

  pages(): number {
    return Math.ceil(this.alerts().length / this.pageSize);
  }

  currentPage(): number {
    return Math.min(this.page, Math.max(0, this.pages() - 1));
  }

  pagedAlerts(): BrokerIntelligentAlert[] {
    const currentPage = this.currentPage();
    return this.alerts().slice(currentPage * this.pageSize, (currentPage + 1) * this.pageSize);
  }
}
