import { Injectable } from '@angular/core';
import { forkJoin } from 'rxjs';
import { ApiService } from '../api.service';

@Injectable({ providedIn: 'root' })
export class BrokerDashboardService {
  constructor(private readonly api: ApiService) {}
  loadDashboard() {
    return forkJoin({ orders: this.api.orders(), executions: this.api.brokerExecutions(), history: this.api.brokerOrderHistory(), rates: this.api.displayExchangeRates(), notifications: this.api.brokerNotifications() });
  }
  orderDetails(orderId: number) { return this.api.brokerOrderDetails(orderId); }
  execute(id: number, quantity: number, price: number) { return this.api.executeOrder(id, quantity, price); }
  reject(id: number, reason: string) { return this.api.rejectBrokerOrder(id, reason); }
}