import { Component, input } from '@angular/core';
import { DecimalPipe } from '@angular/common';
import { CashBalance } from '../../../core/models';
@Component({
  selector: 'app-cash-balances',
  imports: [DecimalPipe],
  template: `<section class="card">
    <h2>Numerar disponibil</h2>
    <div class="balances">
      @for (balance of balances(); track balance.cashAccountId) {
        <article>
          <span>{{ balance.currency }}</span
          ><strong>{{ balance.availableBalance | number: '1.2-2' }}</strong
          ><small>Blocat: {{ balance.blockedBalance | number: '1.2-2' }}</small>
        </article>
      }
    </div>
  </section>`,
  styleUrl: './cash-balances.component.scss',
})
export class CashBalancesComponent {
  balances = input<CashBalance[]>([]);
}
