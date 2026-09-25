import { DatePipe } from '@angular/common';
import { Component, input, output } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Order } from '../../../core/models';

@Component({
  selector: 'app-broker-panel',
  imports: [DatePipe, FormsModule],
  styleUrl: './broker-panel.component.scss',
  templateUrl: './broker-panel.component.html'
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
        && (this.sideFilter === 'ALL' || order.side.toUpperCase() === this.sideFilter.toUpperCase())
        && (this.typeFilter === 'ALL' || order.orderType.toUpperCase() === this.typeFilter.toUpperCase())
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
