import { Component, input } from '@angular/core';
import { DecimalPipe } from '@angular/common';
import { CashBalance } from '../../../core/models';
@Component({
  selector: 'app-cash-balances',
  imports: [DecimalPipe],
  templateUrl: './cash-balances.component.html',
  styleUrl: './cash-balances.component.scss',
})
export class CashBalancesComponent {
  balances = input<CashBalance[]>([]);
}
