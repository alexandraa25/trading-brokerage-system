import { DatePipe } from '@angular/common';
import { Component, input, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { OrderAuditEntry } from '../../core/models/admin.models';

@Component({
  selector: 'app-admin-order-audit',
  imports: [DatePipe, FormsModule],
  templateUrl: './admin-order-audit.component.html',
  styleUrl: './admin-order-audit.component.scss',
})
export class AdminOrderAuditComponent {
  entries = input<OrderAuditEntry[]>([]);
  user = '';
  action = 'ALL';
  orderId = '';
  from = '';
  to = '';
  page = signal(0);
  readonly size = 10;

  filtered() {
    const user = this.user.trim().toLowerCase();
    const orderId = this.orderId.trim();
    return this.entries().filter((entry) =>
      (!user || entry.changedBy.toLowerCase().includes(user)) &&
      (this.action === 'ALL' || entry.activity === this.action) &&
      (!orderId || String(entry.orderId ?? '').includes(orderId)) &&
      (!this.from || entry.changedAt.slice(0, 10) >= this.from) &&
      (!this.to || entry.changedAt.slice(0, 10) <= this.to));
  }
  actions() { return [...new Set(this.entries().map((entry) => entry.activity))]; }
  pages() { return Math.max(1, Math.ceil(this.filtered().length / this.size)); }
  paged() { return this.filtered().slice(this.page() * this.size, (this.page() + 1) * this.size); }
  resetPage() { this.page.set(0); }
  clear() { this.user = ''; this.action = 'ALL'; this.orderId = ''; this.from = ''; this.to = ''; this.page.set(0); }
  actionLabel(activity: string) {
    return ({ OrderEstimate: 'Estimare ordin', PartialCancellation: 'Anulare parțială', StopTriggered: 'STOP declanșat' } as Record<string, string>)[activity] ?? activity;
  }
}
