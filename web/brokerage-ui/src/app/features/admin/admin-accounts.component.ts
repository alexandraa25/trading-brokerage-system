import { Component, computed, input, output, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { AdminAccount } from '../../core/models';

@Component({
  selector: 'app-admin-accounts',
  imports: [FormsModule],
  templateUrl: './admin-accounts.component.html',
  styleUrl: './admin-accounts.component.scss',
})
export class AdminAccountsComponent {
  readonly accounts = input<AdminAccount[]>([]);
  readonly changed = output<{ id: number; status: string; reason: string }>();
  readonly selected = signal<AdminAccount | null>(null);
  reason = '';
  query = '';
  status = 'ALL';
  currency = 'ALL';
  page = signal(0);
  readonly size = 10;
  currencies = computed(() => [...new Set(this.accounts().map((item) => item.currency))].sort());
  filtered() {
    const q = this.query.toLowerCase().trim();
    return this.accounts().filter(
      (item) =>
        (this.status === 'ALL' || item.status === this.status) &&
        (this.currency === 'ALL' || item.currency === this.currency) &&
        (!q ||
          `${item.customerName} ${item.email} ${item.accountNumber}`.toLowerCase().includes(q)),
    );
  }
  pages() {
    return Math.max(1, Math.ceil(this.filtered().length / this.size));
  }
  paged() {
    return this.filtered().slice(this.page() * this.size, (this.page() + 1) * this.size);
  }
  resetFilters() {
    this.query = '';
    this.status = 'ALL';
    this.currency = 'ALL';
    this.page.set(0);
  }
  nextStatus() {
    return this.selected()?.status === 'Active' ? 'Suspended' : 'Active';
  }
  openDecision(account: AdminAccount) {
    this.selected.set(account);
    this.reason = '';
  }
  confirm() {
    const account = this.selected();
    if (account) {
      this.changed.emit({
        id: account.accountId,
        status: this.nextStatus(),
        reason: this.reason.trim(),
      });
      this.selected.set(null);
    }
  }
}
