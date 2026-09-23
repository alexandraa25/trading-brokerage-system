import { Component, computed, input, output } from '@angular/core';
import { Order } from '../../../core/models';

type BrokerAlert = { order: Order; elapsedMinutes: number };

@Component({
  selector: 'app-broker-alerts',
  styleUrl: './broker-alerts.component.scss',
  template: `
    <section class="alerts-card">
      <div class="heading">
        <div><p>ALERTE BROKER</p><h2>Ordine care necesită atenție</h2></div>
        <strong>{{ alerts().length }}</strong>
      </div>

      @if (alerts().length) {
        <div class="alerts-list">
          @for (alert of pagedAlerts(); track alert.order.orderId) {
            <article>
              <div>
                <b>Ordinul #{{ alert.order.orderId }} · {{ alert.order.symbol }}</b>
                <span>{{ alert.order.side === 'Buy' ? 'Cumpărare' : 'Vânzare' }} · {{ alert.order.quantity }} unități · neexecutat de {{ alert.elapsedMinutes }} minute</span>
              </div>
              <button (click)="opened.emit(alert.order.orderId)">Verifică ordinul</button>
            </article>
          }
        </div>
        @if (pages() > 1) {
          <div class="pagination">
            <button [disabled]="currentPage() === 0" (click)="page = currentPage() - 1">Anterior</button>
            <span>Pagina {{ currentPage() + 1 }} din {{ pages() }}</span>
            <button [disabled]="currentPage() + 1 >= pages()" (click)="page = currentPage() + 1">Următor</button>
          </div>
        }
      } @else {
        <p class="empty">Nu există ordine active mai vechi de 15 minute.</p>
      }
    </section>
  `
})
export class BrokerAlertsComponent {
  readonly orders = input<Order[]>([]);
  readonly opened = output<number>();
  readonly pageSize = 5;
  page = 0;

  readonly alerts = computed<BrokerAlert[]>(() => {
    const now = Date.now();
    return this.orders()
      .filter(order => order.status === 'Pending' || order.status === 'PartiallyExecuted')
      .map(order => ({ order, elapsedMinutes: Math.floor((now - new Date(order.createdAt).getTime()) / 60000) }))
      .filter(alert => alert.elapsedMinutes >= 15)
      .sort((left, right) => right.elapsedMinutes - left.elapsedMinutes);
  });

  pages(): number {
    return Math.ceil(this.alerts().length / this.pageSize);
  }

  currentPage(): number {
    return Math.min(this.page, Math.max(0, this.pages() - 1));
  }

  pagedAlerts(): BrokerAlert[] {
    const currentPage = this.currentPage();
    return this.alerts().slice(currentPage * this.pageSize, (currentPage + 1) * this.pageSize);
  }
}
