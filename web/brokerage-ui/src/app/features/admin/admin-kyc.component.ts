import { Component, computed, input, output, signal } from '@angular/core';
import { DatePipe } from '@angular/common';
import { KycRecord } from '../../core/models/admin.models';
@Component({
  selector: 'app-admin-kyc',
  imports: [DatePipe],
  styleUrl: './admin-kyc.component.scss',
  templateUrl: './admin-kyc.component.html',
})
export class AdminKycComponent {
  records = input<KycRecord[]>([]);
  statusChange = output<{
    kycId: number;
    status: 'Approved' | 'Rejected';
    rejectionReason?: string;
  }>();
  query = signal('');
  statusFilter = signal('ALL');
  page = signal(0);
  readonly pageSize = 10;
  recordForRejection = signal<KycRecord | null>(null);
  rejectionReason = signal('');
  filtered = computed(() => {
    const query = this.query().trim().toLowerCase();
    return this.records().filter(
      (record) =>
        (this.statusFilter() === 'ALL' || record.status === this.statusFilter()) &&
        (!query ||
          `${record.firstName} ${record.lastName} ${record.email}`.toLowerCase().includes(query)),
    );
  });
  pageCount = computed(() => Math.max(1, Math.ceil(this.filtered().length / this.pageSize)));
  paged = computed(() =>
    this.filtered().slice(this.page() * this.pageSize, (this.page() + 1) * this.pageSize),
  );
  setQuery(value: string) {
    this.query.set(value);
    this.page.set(0);
  }
  setStatusFilter(value: string) {
    this.statusFilter.set(value);
    this.page.set(0);
  }
  resetFilters() { this.query.set(''); this.statusFilter.set('ALL'); this.page.set(0); }
  previousPage() {
    this.page.update((value) => Math.max(0, value - 1));
  }
  nextPage() {
    this.page.update((value) => Math.min(this.pageCount() - 1, value + 1));
  }
  statusLabel(status: string) {
    return (
      (
        { Pending: 'În așteptare', Approved: 'Aprobat', Rejected: 'Respins' } as Record<
          string,
          string
        >
      )[status] ?? status
    );
  }
  openReject(record: KycRecord) {
    this.recordForRejection.set(record);
    this.rejectionReason.set('');
  }
  closeReject() {
    this.recordForRejection.set(null);
  }
  confirmReject() {
    const record = this.recordForRejection();
    const reason = this.rejectionReason().trim();
    if (record && reason) {
      this.statusChange.emit({ kycId: record.kycId, status: 'Rejected', rejectionReason: reason });
      this.closeReject();
    }
  }
}
