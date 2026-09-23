import { Component, computed, input, output } from '@angular/core';
import { DatePipe, DecimalPipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { CashBalance, CurrencyExchangeQuote } from '../../../core/models';

@Component({
  selector: 'app-currency-exchange-form',
  imports: [DatePipe, DecimalPipe, FormsModule],
  styleUrl: './currency-exchange-form.component.scss',
  template: `<section class="exchange-card">
    <div class="intro">
      <p>SCHIMB VALUTAR</p>
      <h2>Convertește numerar</h2>
      <span
        >Este folosit ultimul curs BCE disponibil. Cursul aplicat rămâne salvat în istoricul
        conversiei.</span
      >
    </div>
    <form (ngSubmit)="submit()">
      <div class="fields">
        <label
          >Din cont<select
            name="sourceAccount"
            [(ngModel)]="sourceCashAccountId"
            (ngModelChange)="accountsChanged()"
          >
            <option [ngValue]="0" disabled>Alege moneda sursă</option>
            @for (balance of balances(); track balance.cashAccountId) {
              <option [ngValue]="balance.cashAccountId">
                {{ balance.currency }} · disponibil {{ balance.availableBalance | number: '1.2-2' }}
              </option>
            }
          </select></label
        ><span class="arrow">→</span
        ><label
          >În cont<select
            name="targetAccount"
            [(ngModel)]="targetCashAccountId"
            (ngModelChange)="accountsChanged()"
          >
            <option [ngValue]="0" disabled>Alege moneda destinație</option>
            @for (balance of targetBalances(); track balance.cashAccountId) {
              <option
                [ngValue]="balance.cashAccountId"
                [disabled]="balance.currency === sourceBalance()?.currency"
              >
                {{ balance.currency
                }}{{ balance.currency === sourceBalance()?.currency ? ' · aceeași monedă' : '' }}
              </option>
            }
          </select></label
        >
      </div>
      <small class="account-help"
        >Sunt afișate toate conturile. Cele în aceeași monedă nu pot fi folosite pentru schimb
        valutar.</small
      ><label
        >Sumă de schimbat<input
          name="sourceAmount"
          type="number"
          min="0.01"
          [attr.max]="sourceBalance()?.availableBalance"
          step="0.01"
          [(ngModel)]="sourceAmount"
          placeholder="0,00"
      /></label>
      @if (quote()) {
        <div class="quote">
          <div>
            <span>Curs aplicat</span
            ><b
              >1 {{ quote()!.sourceCurrency }} = {{ quote()!.exchangeRate | number: '1.4-6' }}
              {{ quote()!.targetCurrency }}</b
            ><small>BCE · actualizat {{ quote()!.sourceRateDate | date: 'dd.MM.yyyy' }}</small>
          </div>
          <div>
            <span>Vei primi</span
            ><b>{{ estimatedAmount() | number: '1.2-4' }} {{ quote()!.targetCurrency }}</b>
          </div>
        </div>
      } @else if (sourceCashAccountId && targetCashAccountId) {
        <small class="waiting">Se caută cursul disponibil...</small>
      }
      <button
        [disabled]="
          !quote() ||
          !sourceAmount ||
          sourceAmount <= 0 ||
          sourceAmount > (sourceBalance()?.availableBalance ?? 0)
        "
      >
        Schimbă valuta
      </button>
    </form>
  </section>`,
})
export class CurrencyExchangeFormComponent {
  balances = input<CashBalance[]>([]);
  quote = input<CurrencyExchangeQuote | null>(null);
  quoteRequested = output<{ sourceCashAccountId: number; targetCashAccountId: number }>();
  exchanged = output<{
    sourceCashAccountId: number;
    targetCashAccountId: number;
    sourceAmount: number;
  }>();
  sourceCashAccountId = 0;
  targetCashAccountId = 0;
  sourceAmount: number | null = null;
  sourceBalance = computed(() =>
    this.balances().find((item) => item.cashAccountId === this.sourceCashAccountId),
  );
  targetBalances = computed(() =>
    this.balances().filter((item) => item.cashAccountId !== this.sourceCashAccountId),
  );
  estimatedAmount = computed(() => (this.sourceAmount ?? 0) * (this.quote()?.exchangeRate ?? 0));
  ngOnChanges() {
    if (!this.sourceCashAccountId && this.balances().length) {
      this.sourceCashAccountId = this.balances()[0].cashAccountId;
      this.targetCashAccountId = this.targetBalances()[0]?.cashAccountId ?? 0;
      this.accountsChanged();
    }
  }
  accountsChanged() {
    const validTargets = this.targetBalances().filter(
      (item) => item.currency !== this.sourceBalance()?.currency,
    );
    if (!validTargets.some((item) => item.cashAccountId === this.targetCashAccountId))
      this.targetCashAccountId = validTargets[0]?.cashAccountId ?? 0;
    if (this.sourceCashAccountId && this.targetCashAccountId)
      this.quoteRequested.emit({
        sourceCashAccountId: this.sourceCashAccountId,
        targetCashAccountId: this.targetCashAccountId,
      });
  }
  submit() {
    const source = this.sourceBalance();
    if (
      source &&
      this.sourceAmount &&
      this.sourceAmount > 0 &&
      this.sourceAmount <= source.availableBalance &&
      this.targetCashAccountId
    ) {
      this.exchanged.emit({
        sourceCashAccountId: source.cashAccountId,
        targetCashAccountId: this.targetCashAccountId,
        sourceAmount: this.sourceAmount,
      });
      this.sourceAmount = null;
    }
  }
}
