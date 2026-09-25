import { Component, computed, input, signal } from '@angular/core';
import { DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { KycAuditEntry } from '../../core/models/admin.models';

@Component({
  selector: 'app-admin-audit',
  imports: [DatePipe, FormsModule],
  styleUrl: './admin-audit.component.scss',
  templateUrl: './admin-audit.component.html',
})
export class AdminAuditComponent {
  entries = input<KycAuditEntry[]>([]);
  query = '';
  from = '';
  to = '';
  page = signal(0);
  readonly size = 10;
  filtered() {
    const q = this.query.toLowerCase();
    return this.entries().filter(
      (x) =>
        (!q || `${x.action} ${x.changedBy}`.toLowerCase().includes(q)) &&
        (!this.from || x.changedAt.slice(0, 10) >= this.from) &&
        (!this.to || x.changedAt.slice(0, 10) <= this.to),
    );
  }
  pageCount() { return Math.max(1, Math.ceil(this.filtered().length / this.size)); }
  paged() { return this.filtered().slice(this.page() * this.size, (this.page() + 1) * this.size); }
  reset() {
    this.page.set(0);
  }
  clearFilters() {
    this.query = '';
    this.from = '';
    this.to = '';
    this.page.set(0);
  }
}
