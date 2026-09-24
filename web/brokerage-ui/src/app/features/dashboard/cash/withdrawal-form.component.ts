import { Component, computed, input, output } from '@angular/core';
import { DecimalPipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { CashBalance } from '../../../core/models';

@Component({
  selector: 'app-withdrawal-form',
  imports: [DecimalPipe, FormsModule],
  styleUrl: './withdrawal-form.component.scss',
  template: `<section class="withdrawal-card">
    <div>
      <p>RETRAGERE NUMERAR</p>
      <h2>Retrage din soldul disponibil</h2>
      <span>Poți retrage doar suma disponibilă în contul selectat.</span>
    </div>
    <form (ngSubmit)="submit()">
      <label
        >Cont de numerar<select name="withdrawCashAccountId" [(ngModel)]="cashAccountId">
          <option [ngValue]="0" disabled>Alege contul</option>
          @for (balance of balances(); track balance.cashAccountId) {
            <option [ngValue]="balance.cashAccountId">
              {{ balance.currency }} · disponibil {{ balance.availableBalance | number: '1.2-2' }}
            </option>
          }
        </select></label
      ><label
        >Sumă<input
          name="withdrawAmount"
          type="number"
          min="0.01"
          [attr.max]="selectedBalance()?.availableBalance"
          step="0.01"
          [(ngModel)]="amount"
          placeholder="0,00" /></label
      ><label class="description"
        >Descriere opțională<input
          name="withdrawDescription"
          maxlength="500"
          [(ngModel)]="description"
          placeholder="Ex.: Retragere demonstrativă"
      /></label>
      @if (selectedBalance()) {
        <small
          >Disponibil pentru retragere:
          <b
            >{{ selectedBalance()!.availableBalance | number: '1.2-2' }}
            {{ selectedBalance()!.currency }}</b
          ></small
        >
      }
      <button
        [disabled]="
          !cashAccountId ||
          !amount ||
          amount <= 0 ||
          amount > (selectedBalance()?.availableBalance ?? 0)
        "
      >
        Înregistrează retragerea
      </button>
    </form>
  </section>`,
})
export class WithdrawalFormComponent {
  balances = input<CashBalance[]>([]);
  withdrawn = output<{ cashAccountId: number; amount: number; description: string }>();
  cashAccountId = 0;
  amount: number | null = null;
  description = '';
  selectedBalance = computed(() =>
    this.balances().find((item) => item.cashAccountId === this.cashAccountId),
  );
  ngOnChanges() {
    if (!this.cashAccountId && this.balances().length)
      this.cashAccountId = this.balances()[0].cashAccountId;
  }
  submit() {
    const balance = this.selectedBalance();
    if (balance && this.amount && this.amount > 0 && this.amount <= balance.availableBalance) {
      this.withdrawn.emit({
        cashAccountId: balance.cashAccountId,
        amount: this.amount,
        description: this.description.trim(),
      });
      this.amount = null;
      this.description = '';
    }
  }
}
