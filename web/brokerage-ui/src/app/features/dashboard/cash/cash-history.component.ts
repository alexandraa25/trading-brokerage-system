import { Component, computed, input, signal } from '@angular/core';
import { DatePipe, DecimalPipe } from '@angular/common';
import { CashTransaction } from '../../../core/models';

@Component({
  selector: 'app-cash-history',
  imports: [DatePipe, DecimalPipe],
  styleUrl: './cash-history.component.scss',
  templateUrl: './cash-history.component.html',
})
export class CashHistoryComponent {
  transactions = input<CashTransaction[]>([]);
  typeFilter = signal('ALL');
  page = signal(0);
  readonly size = 10;
  filtered = computed(() =>
    this.transactions().filter(
      (item) => this.typeFilter() === 'ALL' || item.transactionType === this.typeFilter(),
    ),
  );
  pageCount = computed(() => Math.max(1, Math.ceil(this.filtered().length / this.size)));
  paged = computed(() =>
    this.filtered().slice(this.page() * this.size, (this.page() + 1) * this.size),
  );
  setFilter(value: string) {
    this.typeFilter.set(value);
    this.page.set(0);
  }
  previous() {
    this.page.update((value) => Math.max(0, value - 1));
  }
  next() {
    this.page.update((value) => Math.min(this.pageCount() - 1, value + 1));
  }
  typeLabel(type: string) {
    return (
      (
        {
          Deposit: 'Depunere',
          Trade: 'Tranzacție',
          Commission: 'Comision',
          Withdrawal: 'Retragere',
          CurrencyExchangeOut: 'Schimb valutar trimis',
          CurrencyExchangeIn: 'Schimb valutar primit',
          Adjustment: 'Ajustare',
        } as Record<string, string>
      )[type] ?? type
    );
  }
}
