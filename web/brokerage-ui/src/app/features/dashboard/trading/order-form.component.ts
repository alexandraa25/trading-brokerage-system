import { Component, inject, input, output, signal } from '@angular/core';
import { DatePipe, DecimalPipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Account, Instrument } from '../../../core/models';
import { CreateOrderRequest, OrderEstimate } from '../../../core/models/admin.models';
import { ApiService } from '../../../core/api.service';
@Component({
  selector: 'app-order-form',
  imports: [FormsModule, DecimalPipe, DatePipe],
  templateUrl: './order-form.component.html',
  styleUrl: './order-form.component.scss',
})
export class OrderFormComponent {
  private readonly api = inject(ApiService);
  accounts = input<Account[]>([]);
  instruments = input<Instrument[]>([]);
  submitted = output<CreateOrderRequest>();
  accountId = 0;
  instrumentId = 0;
  side: CreateOrderRequest['side'] = 'BUY';
  orderType: CreateOrderRequest['orderType'] = 'MARKET';
  quantity = 1;
  limitPrice: number | null = null;
  stopPrice: number | null = null;
  selectedInstrument() { return this.instruments().find(x => x.instrumentId === +this.instrumentId); }
  estimatedPrice() { return this.limitPrice ?? this.stopPrice ?? this.selectedInstrument()?.marketPrice ?? 0; }
  estimatedValue() { return (+this.quantity || 0) * this.estimatedPrice(); }
  estimatedCommission() { return this.estimatedValue() * 0.0025; }
  estimatedTotal() { return this.estimatedValue() + this.estimatedCommission(); }
  confirmOpen = signal(false);
  estimate = signal<OrderEstimate | null>(null);
  estimateLoading = signal(false);
  estimateError = signal('');

  private request(): CreateOrderRequest {
    return {
      accountId: +this.accountId, instrumentId: +this.instrumentId, side: this.side,
      orderType: this.orderType, quantity: +this.quantity,
      limitPrice: this.orderType === 'LIMIT' || this.orderType === 'STOP_LIMIT' ? +this.limitPrice! : null,
      stopPrice: this.orderType === 'STOP' || this.orderType === 'STOP_LIMIT' ? +this.stopPrice! : null,
    };
  }
  submit() {
    if (!this.confirmOpen()) {
      this.estimateLoading.set(true); this.estimateError.set(''); this.estimate.set(null);
      this.api.estimateOrder(this.request()).subscribe({
        next: estimate => { this.estimate.set(estimate); this.estimateLoading.set(false); this.confirmOpen.set(true); },
        error: error => { this.estimateError.set(error.error?.detail ?? 'Estimarea nu a putut fi calculată.'); this.estimateLoading.set(false); },
      });
      return;
    }
    if (!this.estimate()?.canSubmit) return;
    this.submitted.emit(this.request());
    this.confirmOpen.set(false);
  }
}
