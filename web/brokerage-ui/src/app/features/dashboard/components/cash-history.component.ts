import { Component, computed, input, signal } from '@angular/core';
import { DatePipe, DecimalPipe } from '@angular/common';
import { CashTransaction } from '../../../core/models';

@Component({
  selector: 'app-cash-history',
  imports: [DatePipe, DecimalPipe],
  styleUrl: './cash-history.component.scss',
  template: `<section class="card">
    <div class="heading">
      <div>
        <p>ISTORIC NUMERAR</p>
        <h2>Operațiuni cu numerar</h2>
        <span>Depuneri și mișcări generate de ordinele executate.</span>
      </div>
      <strong>{{ filtered().length }} operațiuni</strong>
    </div>
    <div class="filters">
      <select [value]="typeFilter()" (change)="setFilter($any($event.target).value)">
        <option value="ALL">Toate operațiunile</option>
        <option value="Deposit">Depuneri</option>
        <option value="Trade">Tranzacții</option>
        <option value="Commission">Comisioane</option>
        <option value="Withdrawal">Retrageri</option>
        <option value="CurrencyExchangeOut">Schimb valutar</option>
        <option value="Adjustment">Ajustări</option>
      </select>
    </div>
    @if (paged().length) {
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Data</th>
              <th>Tip</th>
              <th>Sumă</th>
              <th>Descriere</th>
              <th>Referință</th>
            </tr>
          </thead>
          <tbody>
            @for (item of paged(); track item.cashTransactionId) {
              <tr>
                <td>{{ item.createdAt | date: 'dd.MM.yyyy, HH:mm' }}</td>
                <td>
                  <span
                    class="type"
                    [class.deposit]="
                      item.transactionType === 'Deposit' ||
                      item.transactionType === 'CurrencyExchangeIn'
                    "
                    [class.debit]="item.amount < 0"
                    >{{ typeLabel(item.transactionType) }}</span
                  >
                </td>
                <td [class.negative]="item.amount < 0" [class.positive]="item.amount > 0">
                  <b
                    >{{ item.amount > 0 ? '+' : '' }}{{ item.amount | number: '1.2-2' }}
                    {{ item.currency }}</b
                  >
                </td>
                <td>{{ item.description || '—' }}</td>
                <td>
                  {{ item.referenceType || '—' }}
                  @if (item.referenceId) {
                    #{{ item.referenceId }}
                  }
                </td>
              </tr>
            }
          </tbody>
        </table>
      </div>
      <div class="pagination">
        <button [disabled]="page() === 0" (click)="previous()">‹ Anterior</button
        ><span>Pagina {{ page() + 1 }} din {{ pageCount() }}</span
        ><button [disabled]="page() + 1 >= pageCount()" (click)="next()">Următor ›</button>
      </div>
    } @else {
      <div class="empty">
        <b>Nu există operațiuni pentru filtrul selectat.</b
        ><span>Depunerile și ordinele executate vor apărea aici.</span>
      </div>
    }
  </section>`,
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
