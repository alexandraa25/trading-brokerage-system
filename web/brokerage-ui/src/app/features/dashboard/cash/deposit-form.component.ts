import { Component, input, output } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { DecimalPipe } from '@angular/common';
import { Account, CashBalance } from '../../../core/models';

@Component({
  selector: 'app-deposit-form',
  imports: [FormsModule, DecimalPipe],
  styleUrl: './deposit-form.component.scss',
  templateUrl: './deposit-form.component.html',
})
export class DepositFormComponent {
  balances = input<CashBalance[]>([]);
  accounts = input<Account[]>([]);
  deposited = output<{ cashAccountId: number; amount: number; description: string }>();
  cashAccountOpened = output<{ accountId: number; currency: string }>();
  cashAccountId = 0;
  amount: number | null = null;
  description = '';
  accountDialogOpen = false;
  newAccountId = 0;
  newCurrency = 'EUR';
  readonly currencies = ['EUR', 'USD', 'GBP', 'RON', 'CAD', 'JPY'];
  ngOnChanges() {
    if (!this.cashAccountId && this.balances().length)
      this.cashAccountId = this.balances()[0].cashAccountId;
  }
  openAccountDialog() {
    this.newAccountId = this.accounts()[0]?.accountId ?? 0;
    this.newCurrency =
      this.currencies.find(
        (currency) => !this.balances().some((balance) => balance.currency === currency),
      ) ?? 'EUR';
    this.accountDialogOpen = true;
  }
  createCashAccount() {
    if (this.newAccountId) {
      this.cashAccountOpened.emit({ accountId: this.newAccountId, currency: this.newCurrency });
      this.accountDialogOpen = false;
    }
  }
  submit() {
    if (this.cashAccountId && this.amount && this.amount > 0) {
      this.deposited.emit({
        cashAccountId: this.cashAccountId,
        amount: this.amount,
        description: this.description.trim(),
      });
      this.amount = null;
      this.description = '';
    }
  }
}
