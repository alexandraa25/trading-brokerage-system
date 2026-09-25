import { Component, input, output, signal } from '@angular/core';
import { DatePipe, DecimalPipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Order } from '../../../core/models';
@Component({
  selector: 'app-orders-history',
  imports: [DatePipe, DecimalPipe, FormsModule],
  templateUrl: './orders-history.component.html',
  styleUrl: './orders-history.component.scss',
})
export class OrdersHistoryComponent {
  orders = input<Order[]>([]);
  cancel = output<number>();
  partialCancel = output<{ orderId: number; quantity: number }>();
  partialOrder = signal<Order | null>(null);
  partialQuantity: number | null = null;

  openPartialCancel(order: Order) {
    this.partialOrder.set(order);
    this.partialQuantity = null;
  }

  confirmPartialCancel() {
    const order = this.partialOrder();
    if (!order || !this.partialQuantity || this.partialQuantity <= 0 || this.partialQuantity > order.quantity) return;
    this.partialCancel.emit({ orderId: order.orderId, quantity: this.partialQuantity });
    this.partialOrder.set(null);
  }

  statusLabel(order: Order) {
    if (order.cancelledQuantity > 0 && order.remainingQuantity > 0) return 'Anulat parțial';
    return ({
      WaitingTrigger: 'În așteptare declanșare',
      Triggered: 'Declanșat',
      Pending: 'În așteptare',
      PartiallyExecuted: 'Executat parțial',
      Executed: 'Executat',
      Cancelled: 'Anulat',
      Rejected: 'Respins',
    } as Record<string, string>)[order.status] ?? order.status;
  }
}
