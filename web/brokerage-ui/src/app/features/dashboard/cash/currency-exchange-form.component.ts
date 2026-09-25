import { Component, computed, input, output } from '@angular/core';
import { DatePipe, DecimalPipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { CashBalance, CurrencyExchangeQuote } from '../../../core/models';

@Component({
  selector: 'app-currency-exchange-form',
  imports: [DatePipe, DecimalPipe, FormsModule],
  styleUrl: './currency-exchange-form.component.scss',
  templateUrl: './currency-exchange-form.component.html',
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
