import { Component, input, output } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Account, Instrument } from '../../../core/models';
@Component({
  selector: 'app-order-form',
  imports: [FormsModule],
  template: `<section class="card">
    <p class="eyebrow">TRANZACȚIONARE</p>
    <h2>Plasează un ordin</h2>
    <form (ngSubmit)="submit()">
      <label
        >Cont<select [(ngModel)]="accountId" name="account">
          @for (a of accounts(); track a.accountId) {
            <option [value]="a.accountId">{{ a.accountNumber }}</option>
          }
        </select></label
      ><label
        >Instrument<select [(ngModel)]="instrumentId" name="instrument">
          @for (i of instruments(); track i.instrumentId) {
            <option [value]="i.instrumentId">{{ i.symbol }} — {{ i.instrumentName }}</option>
          }
        </select></label
      ><label
        >Acțiune<select [(ngModel)]="side" name="side">
          <option value="BUY">Cumpărare</option>
          <option value="SELL">Vânzare</option>
        </select></label
      ><label
        >Tip ordin<select [(ngModel)]="orderType" name="orderType">
          <option value="MARKET">La piață</option>
          <option value="LIMIT">Limită</option>
        </select></label
      ><label
        >Cantitate<input
          [(ngModel)]="quantity"
          name="quantity"
          type="number"
          min="0.0001"
          step="0.0001" /></label
      >@if (orderType === 'LIMIT') {
        <label>Preț limită<input [(ngModel)]="limitPrice" name="limitPrice" type="number" min="0.0001" step="0.0001" required /></label>
      }
      ><button>Trimite ordinul</button>
    </form>
  </section>`,
  styleUrl: './order-form.component.scss',
})
export class OrderFormComponent {
  accounts = input<Account[]>([]);
  instruments = input<Instrument[]>([]);
  submitted = output<any>();
  accountId = 0;
  instrumentId = 0;
  side = 'BUY';
  orderType = 'MARKET';
  quantity = 1;
  limitPrice: number | null = null;
  submit() {
    this.submitted.emit({
      accountId: +this.accountId,
      instrumentId: +this.instrumentId,
      side: this.side,
      orderType: this.orderType,
      quantity: +this.quantity,
      limitPrice: this.orderType === 'LIMIT' ? +this.limitPrice! : null,
    });
  }
}
