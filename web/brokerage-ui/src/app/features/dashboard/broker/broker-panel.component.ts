import { DatePipe } from '@angular/common';
import { Component, input, output } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Order } from '../../../core/models';

@Component({
  selector: 'app-broker-panel',
  imports: [DatePipe, FormsModule],
  styleUrl: './broker-panel.component.scss',
  template: `
    <section class="card">
      <p>PANOU BROKER</p>
      <h2>Ordine în așteptare</h2>

      <div class="filters">
        <input [(ngModel)]="symbolFilter" (ngModelChange)="resetPage()" placeholder="Caută simbol" />
        <select [(ngModel)]="sideFilter" (ngModelChange)="resetPage()">
          <option value="ALL">Cumpărare și vânzare</option>
          <option value="Buy">Cumpărare</option>
          <option value="Sell">Vânzare</option>
        </select>
        <select [(ngModel)]="typeFilter" (ngModelChange)="resetPage()">
          <option value="ALL">Toate tipurile</option>
          <option value="Market">La piață</option>
          <option value="Limit">Limită</option>
        </select>
        <label>De la
          <input type="date" [(ngModel)]="fromDate" (ngModelChange)="resetPage()" />
        </label>
        <label>Până la
          <input type="date" [(ngModel)]="toDate" (ngModelChange)="resetPage()" />
        </label>
        <select [(ngModel)]="sortBy" (ngModelChange)="resetPage()">
          <option value="newest">Cele mai noi</option>
          <option value="oldest">Cele mai vechi</option>
          <option value="quantity">Cantitate descrescător</option>
        </select>
      </div>

      <p class="count">{{ filtered().length }} ordine active afișate</p>

      <div class="orders">
        @for (order of paged(); track order.orderId) {
          <article>
            <div>
              <b>#{{ order.orderId }} · {{ order.symbol }}</b>
              <span>{{ order.side }} · {{ order.quantity }} · {{ order.orderType }} · {{ order.createdAt | date:'dd.MM.yyyy HH:mm' }}</span>
            </div>
            <button class="details" (click)="details.emit(order.orderId)">Detalii și execuție</button>
          </article>
        } @empty {
          <p>Nu există ordine pentru filtrele alese.</p>
        }
      </div>

      @if (pages() > 1) {
        <div class="pagination">
          <button [disabled]="page === 0" (click)="page = page - 1">Anterior</button>
          <span>Pagina {{ page + 1 }} din {{ pages() }}</span>
          <button [disabled]="page + 1 >= pages()" (click)="page = page + 1">Următor</button>
        </div>
      }
    </section>
  `
})
export class BrokerPanelComponent {
  readonly orders = input<Order[]>([]);
  readonly details = output<number>();
  readonly size = 10;

  sideFilter = 'ALL';
  typeFilter = 'ALL';
  symbolFilter = '';
  fromDate = '';
  toDate = '';
  sortBy = 'newest';
  page = 0;

  resetPage(): void {
    this.page = 0;
  }

  filtered(): Order[] {
    const symbol = this.symbolFilter.trim().toLowerCase();
    const from = this.fromDate ? new Date(`${this.fromDate}T00:00:00`) : null;
    const to = this.toDate ? new Date(`${this.toDate}T23:59:59`) : null;

    const items = this.orders().filter(order => {
      const createdAt = new Date(order.createdAt);
      return (order.status === 'Pending' || order.status === 'PartiallyExecuted')
        && (this.sideFilter === 'ALL' || order.side === this.sideFilter)
        && (this.typeFilter === 'ALL' || order.orderType === this.typeFilter)
        && (!symbol || order.symbol.toLowerCase().includes(symbol))
        && (!from || createdAt >= from)
        && (!to || createdAt <= to);
    });

    return items.sort((left, right) => {
      if (this.sortBy === 'quantity') {
        return right.quantity - left.quantity;
      }

      const difference = new Date(right.createdAt).getTime() - new Date(left.createdAt).getTime();
      return this.sortBy === 'oldest' ? -difference : difference;
    });
  }

  pages(): number {
    return Math.ceil(this.filtered().length / this.size);
  }

  paged(): Order[] {
    return this.filtered().slice(this.page * this.size, (this.page + 1) * this.size);
  }
}
