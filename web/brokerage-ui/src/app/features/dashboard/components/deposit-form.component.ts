import { Component, input, output } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { DecimalPipe } from '@angular/common';
import { Account, CashBalance } from '../../../core/models';

@Component({
  selector: 'app-deposit-form',
  imports: [FormsModule, DecimalPipe],
  styleUrl: './deposit-form.component.scss',
  template: `<section class="deposit-card">
      <div>
        <p>ALIMENTARE CONT</p>
        <h2>Depune numerar</h2>
        <span>În această aplicație demonstrativă, depunerea este înregistrată imediat.</span
        ><button type="button" class="new-account" (click)="openAccountDialog()">
          + Deschide cont în altă monedă
        </button>
      </div>
      <form (ngSubmit)="submit()">
        <label
          >Cont de numerar<select name="cashAccountId" [(ngModel)]="cashAccountId">
            <option [ngValue]="0" disabled>Alege contul</option>
            @for (balance of balances(); track balance.cashAccountId) {
              <option [ngValue]="balance.cashAccountId">
                {{ balance.currency }} · disponibil {{ balance.availableBalance | number: '1.2-2' }}
              </option>
            }
          </select></label
        ><label
          >Sumă<input
            name="amount"
            type="number"
            min="0.01"
            step="0.01"
            [(ngModel)]="amount"
            placeholder="0,00" /></label
        ><label class="description"
          >Descriere opțională<input
            name="description"
            maxlength="500"
            [(ngModel)]="description"
            placeholder="Ex.: Alimentare portofoliu" /></label
        ><button [disabled]="!cashAccountId || !amount || amount <= 0">
          Înregistrează depunerea
        </button>
      </form>
    </section>
    @if (accountDialogOpen) {
      <div class="modal-backdrop">
        <section class="account-modal">
          <p>CONT NOU DE NUMERAR</p>
          <h2>Alege moneda</h2>
          <span
            >Contul nou este creat cu sold zero. După creare, îl poți selecta pentru depunere.</span
          ><label
            >Cont de tranzacționare<select name="newAccountId" [(ngModel)]="newAccountId">
              <option [ngValue]="0" disabled>Alege contul</option>
              @for (account of accounts(); track account.accountId) {
                <option [ngValue]="account.accountId">
                  {{ account.accountNumber }} · {{ account.currency }}
                </option>
              }
            </select></label
          ><label
            >Monedă<select name="newCurrency" [(ngModel)]="newCurrency">
              @for (currency of currencies; track currency) {
                <option [value]="currency">{{ currency }}</option>
              }
            </select></label
          >
          <div class="modal-actions">
            <button type="button" class="secondary" (click)="accountDialogOpen = false">
              Anulează</button
            ><button type="button" [disabled]="!newAccountId" (click)="createCashAccount()">
              Deschide contul
            </button>
          </div>
        </section>
      </div>
    }`,
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
