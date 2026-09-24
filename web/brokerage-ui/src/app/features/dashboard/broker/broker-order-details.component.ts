import { Component, input, output } from '@angular/core';
import { DecimalPipe, DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { BrokerOrderDetails } from '../../../core/models/admin.models';
@Component({
  selector: 'app-broker-order-details',
  imports: [DecimalPipe, DatePipe, FormsModule],
  styleUrl: './broker-order-details.component.scss',
  template: `@if (details()) {
    <div class="overlay">
      <section class="modal">
        <button class="close" (click)="closed.emit()">×</button>
        <p>DETALII ORDIN #{{ details()!.orderId }}</p>
        <h2>{{ details()!.symbol }} · {{ details()!.side === 'BUY' ? 'Cumpărare' : 'Vânzare' }}</h2>
        <span
          >{{ details()!.instrumentName }} · {{ details()!.orderType }} · creat
          {{ details()!.createdAt | date: 'dd.MM.yyyy HH:mm' }}</span
        >
        <div class="grid">
          <article>
            <span>Client</span><b>{{ details()!.firstName }} {{ details()!.lastName }}</b
            ><small>{{ details()!.email }}</small>
          </article>
          <article>
            <span>Cont</span><b>{{ details()!.accountNumber }}</b
            ><small>Monedă instrument: {{ details()!.currency }}</small>
          </article>
          <article>
            <span>Disponibil</span
            ><b>{{ details()!.availableCash | number: '1.2-2' }} {{ details()!.currency }}</b
            ><small>Blocat: {{ details()!.blockedCash | number: '1.2-2' }}</small>
          </article>
          <article>
            <span>Poziție curentă</span
            ><b>{{ details()!.positionQuantity | number: '1.2-4' }} unități</b
            ><small>Preț mediu: {{ details()!.averagePrice | number: '1.2-4' }}</small>
          </article>
        </div>
        <div class="order-values">
          <span
            >Cantitate ordin: <b>{{ details()!.quantity | number: '1.2-4' }}</b></span
          ><span
            >Deja executat: <b>{{ details()!.executedQuantity | number: '1.2-4' }}</b></span
          >
          @if (details()!.limitPrice) {
            <span
              >Preț limită:
              <b>{{ details()!.limitPrice | number: '1.2-4' }} {{ details()!.currency }}</b></span
            >
          }
        </div>
        <section class="quote">
          <div>
            <p>PREȚ DE REFERINȚĂ</p>
            @if (details()!.marketPrice !== null) {
              <strong
                >{{ details()!.marketPrice | number: '1.2-4' }} {{ details()!.currency }}</strong
              ><small>Ultima cotație: {{ details()!.quoteDate | date: 'dd.MM.yyyy HH:mm' }}</small>
            } @else {
              <strong>Indisponibil</strong
              ><small>Nu există o cotație salvată pentru acest instrument.</small>
            }
          </div>
          <span>
            @if (details()!.orderType === 'Limit') {
              Pentru {{ details()!.side === 'BUY' ? 'cumpărare' : 'vânzare' }}, prețul trebuie să
              respecte limita ordinului.
            } @else {
              Pentru ordinul la piață, pornește de la ultima cotație și verifică execuția înainte de
              confirmare.
            }
          </span>
        </section>
        @if (!rejecting) {
          <div class="execution">
            <label
              >Cantitate de executat<input
                type="number"
                [(ngModel)]="quantity"
                min="0.0001"
                [max]="remaining()"
                step="0.0001" /></label
            ><label
              >Preț execuție<input
                type="number"
                [(ngModel)]="price"
                min="0.0001"
                step="0.0001" /></label
            ><button
              [disabled]="executionFeedback() !== null"
              (click)="execute.emit({ id: details()!.orderId, quantity: quantity!, price: price! })"
            >
              Confirmă execuția
            </button>
          </div>
          @if (executionFeedback()) {
            <p class="feedback">{{ executionFeedback() }}</p>
          } @else {
            <p class="ready">
              Execuția respectă verificările disponibile. Comision estimat:
              {{ estimatedCommission() | number: '1.2-2' }} {{ details()!.currency }}.
            </p>
          }
          <button class="reject" (click)="rejecting = true">Respinge ordinul</button>
        } @else {
          <div class="rejection">
            <label
              >Motivul respingerii<textarea
                [(ngModel)]="reason"
                maxlength="500"
                placeholder="Explică de ce ordinul nu poate fi executat."
              ></textarea>
            </label>
            <div>
              <button class="secondary" (click)="rejecting = false">Înapoi</button
              ><button
                class="reject"
                [disabled]="reason.trim().length < 3"
                (click)="reject.emit({ id: details()!.orderId, reason: reason.trim() })"
              >
                Confirmă respingerea
              </button>
            </div>
          </div>
        }
      </section>
    </div>
  }`,
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
      return 'Prețul de execuție depășește prețul limită acceptat pentru cumpărare.';
    if (item.side === 'SELL' && item.limitPrice !== null && this.price < item.limitPrice)
      return 'Prețul de execuție este sub prețul limită acceptat pentru vânzare.';
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
