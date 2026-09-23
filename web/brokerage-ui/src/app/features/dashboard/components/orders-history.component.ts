import { Component, input, output } from '@angular/core';
import { DatePipe, DecimalPipe } from '@angular/common';
import { Order } from '../../../core/models';
@Component({
  selector: 'app-orders-history',
  imports: [DatePipe, DecimalPipe],
  template: `<section class="card">
    <div class="head">
      <div>
        <p>ACTIVITATE</p>
        <h2>Istoric ordine</h2>
      </div>
    </div>
    @if (orders().length) {
      <div class="wrap">
        <table>
          <thead>
            <tr>
              <th>Instrument</th>
              <th>Acțiune</th>
              <th>Cantitate</th>
              <th>Stare</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            @for (o of orders(); track o.orderId) {
              <tr>
                <td>
                  <b>{{ o.symbol }}</b
                  ><br /><small>{{ o.createdAt | date: 'dd MMM yyyy' }}</small>
                </td>
                <td>{{ o.side === 'BUY' ? 'Cumpărare' : 'Vânzare' }}</td>
                <td>{{ o.quantity | number: '1.0-4' }}</td>
                <td>
                  <span [class]="'status ' + o.status">{{ o.status }}</span>
                </td>
                <td>
                  @if (o.status === 'Pending' || o.status === 'PartiallyExecuted') {
                    <button (click)="cancel.emit(o.orderId)">Anulează</button>
                  }
                </td>
              </tr>
            }
          </tbody>
        </table>
      </div>
    } @else {
      <p class="empty">Nu există ordine înregistrate.</p>
    }
  </section>`,
  styleUrl: './orders-history.component.scss',
})
export class OrdersHistoryComponent {
  orders = input<Order[]>([]);
  cancel = output<number>();
}
