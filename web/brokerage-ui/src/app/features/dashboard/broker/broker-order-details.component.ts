import { Component, input, output } from '@angular/core';
import { DecimalPipe, DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { BrokerOrderDetails } from '../../../core/models/admin.models';
@Component({
  selector: 'app-broker-order-details',
  imports: [DecimalPipe, DatePipe, FormsModule],
  styleUrl: './broker-order-details.component.scss',
  templateUrl: './broker-order-details.component.html',
})
export class BrokerOrderDetailsComponent {
  readonly details = input<BrokerOrderDetails | null>(null);
  readonly closed = output<void>();
  readonly execute = output<{ id: number; quantity: number; price: number }>();
  readonly reject = output<{ id: number; reason: string }>();
  quantity: number | null = null;
  price: number | null = null;
  rejecting = false;
  reason = '';

  remaining() {
    const item = this.details();
    return item ? Math.max(0, item.quantity - item.executedQuantity) : 0;
  }
  estimatedCommission() {
    return (this.quantity ?? 0) * (this.price ?? 0) * 0.0025;
  }

  executionFeedback(): string | null {
    const item = this.details();
    if (!item || !this.quantity || !this.price || this.quantity <= 0 || this.price <= 0)
      return 'Completează o cantitate și un preț de execuție mai mari decât zero.';
    if (this.quantity > this.remaining())
      return 'Cantitatea propusă depășește cantitatea rămasă din ordin.';
    if (item.side === 'BUY' && item.limitPrice !== null && this.price > item.limitPrice)
      return item.orderType === 'STOP_LIMIT' ? 'STOP-LIMIT nu poate fi executat: prețul propus depășește limita clientului.' : 'Prețul de execuție depășește prețul limită acceptat pentru cumpărare.';
    if (item.side === 'SELL' && item.limitPrice !== null && this.price < item.limitPrice)
      return item.orderType === 'STOP_LIMIT' ? 'STOP-LIMIT nu poate fi executat: prețul propus este sub limita clientului.' : 'Prețul de execuție este sub prețul limită acceptat pentru vânzare.';
    if (item.side === 'BUY' && this.quantity * this.price * 1.0025 > item.availableCash)
      return 'Soldul disponibil nu acoperă valoarea execuției și comisionul estimat de 0,25%.';
    if (item.side === 'SELL' && this.quantity > item.positionQuantity)
      return 'Poziția clientului nu acoperă cantitatea propusă pentru vânzare.';
    return null;
  }

  ngOnChanges() {
    const item = this.details();
    if (item) {
      this.quantity = this.remaining();
      this.price = item.marketPrice ?? item.limitPrice;
      this.rejecting = false;
      this.reason = '';
    }
  }
}
