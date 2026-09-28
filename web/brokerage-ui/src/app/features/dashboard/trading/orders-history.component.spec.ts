import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideZonelessChangeDetection } from '@angular/core';
import { OrdersHistoryComponent } from './orders-history.component';

describe('OrdersHistoryComponent', () => {
  let fixture: ComponentFixture<OrdersHistoryComponent>;
  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [OrdersHistoryComponent], providers: [provideZonelessChangeDetection()] }).compileComponents();
    fixture = TestBed.createComponent(OrdersHistoryComponent);
    fixture.componentRef.setInput('orders', [{ orderId: 1, symbol: 'TEST', side: 'BUY', orderType: 'STOP_LIMIT', quantity: 8, limitPrice: 110, stopPrice: 105, originalQuantity: 10, executedQuantity: 1, cancelledQuantity: 2, remainingQuantity: 7, status: 'Pending', createdAt: '2026-09-28T00:00:00Z' }]);
    fixture.detectChanges();
  });
  it('afișează starea anulat parțial când există cantitate anulată', () => {
    expect(fixture.componentInstance.statusLabel(fixture.componentInstance.orders()[0])).toBe('Anulat parțial');
  });
  it('deschide pop-up-ul pentru anulare parțială', () => {
    fixture.componentInstance.openPartialCancel(fixture.componentInstance.orders()[0]);
    expect(fixture.componentInstance.partialOrder()?.orderId).toBe(1);
  });
});
