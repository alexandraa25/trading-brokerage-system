import { Component, computed, input, output, signal } from '@angular/core';
import { DatePipe } from '@angular/common';

export type KycRecord = {
  kycId: number;
  customerId: number;
  firstName: string;
  lastName: string;
  email: string;
  customerStatus: string;
  status: string;
  documentType: string;
  createdAt: string;
  updatedAt: string | null;
  rejectionReason: string | null;
};

@Component({
  selector: 'app-admin-kyc',
  imports: [DatePipe],
  styleUrl: './admin-kyc.component.scss',
  template: `<section class="card">
    <div class="heading">
      <div>
        <p>ADMINISTRARE</p>
        <h2>Dosare KYC</h2>
        <span>Verifică identitatea clienților și actualizează starea dosarului.</span>
      </div>
      <strong>{{ filtered().length }} dosare</strong>
    </div>
    <div class="filters">
      <input
        placeholder="Caută nume sau e-mail"
        [value]="query()"
        (input)="setQuery($any($event.target).value)"
      /><select [value]="statusFilter()" (change)="setStatusFilter($any($event.target).value)">
        <option value="ALL">Toate stările</option>
        <option value="Pending">În așteptare</option>
        <option value="Approved">Aprobate</option>
        <option value="Rejected">Respinse</option>
      </select>
    </div>
    @if (filtered().length) {
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Client</th>
              <th>Document</th>
              <th>Stare KYC</th>
              <th>Cont</th>
              <th>Creat la</th>
              <th>Acțiuni</th>
            </tr>
          </thead>
          <tbody>
            @for (record of paged(); track record.kycId) {
              <tr>
                <td>
                  <b>{{ record.firstName }} {{ record.lastName }}</b
                  ><br /><small>{{ record.email }}</small>
                </td>
                <td>{{ record.documentType || 'Necompletat' }}</td>
                <td>
                  <span
                    class="status"
                    [class.pending]="record.status === 'Pending'"
                    [class.approved]="record.status === 'Approved'"
                    [class.rejected]="record.status === 'Rejected'"
                    >{{ statusLabel(record.status) }}</span
                  >
                </td>
                <td>{{ record.customerStatus }}</td>
                <td>{{ record.createdAt | date: 'dd.MM.yyyy' }}</td>
                <td>
                  @if (record.status === 'Pending') {
                    <div class="actions">
                      <button
                        class="approve"
                        (click)="statusChange.emit({ kycId: record.kycId, status: 'Approved' })"
                      >
                        Aprobă</button
                      ><button class="reject" (click)="openReject(record)">Respinge</button>
                    </div>
                  } @else {
                    <span class="done">Finalizat</span>
                  }
                </td>
              </tr>
            }
          </tbody>
        </table>
      </div>
      <div class="pagination">
        <button [disabled]="page() === 0" (click)="previousPage()">‹ Anterior</button
        ><span>Pagina {{ page() + 1 }} din {{ pageCount() }}</span
        ><button [disabled]="page() + 1 >= pageCount()" (click)="nextPage()">Următor ›</button>
      </div>
    } @else {
      <div class="empty"><b>Nu am găsit dosare KYC.</b></div>
    }
  </section>`,
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
