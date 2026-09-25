import { Component, computed, input, output } from '@angular/core';
import { DecimalPipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { CashBalance } from '../../../core/models';

@Component({
  selector: 'app-withdrawal-form',
  imports: [DecimalPipe, FormsModule],
  styleUrl: './withdrawal-form.component.scss',
  templateUrl: './withdrawal-form.component.html',
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
