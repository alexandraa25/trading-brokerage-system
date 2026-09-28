import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideZonelessChangeDetection } from '@angular/core';
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { OrderFormComponent } from './order-form.component';

describe('OrderFormComponent', () => {
  let fixture: ComponentFixture<OrderFormComponent>;
  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [OrderFormComponent], providers: [provideZonelessChangeDetection(), provideHttpClient(), provideHttpClientTesting()] }).compileComponents();
    fixture = TestBed.createComponent(OrderFormComponent);
    fixture.componentRef.setInput('accounts', [{ accountId: 1, accountNumber: 'EUR-1', currency: 'EUR', status: 'Active' }]);
    fixture.componentRef.setInput('instruments', [{ instrumentId: 2, symbol: 'TEST', instrumentName: 'Test', instrumentType: 'Stock', currency: 'EUR', marketName: '', issuerName: '', marketPrice: 100, quoteDate: null, quoteSource: null }]);
    fixture.detectChanges();
  });
  it('calculează imediat comisionul de 0,25%', () => {
    const component = fixture.componentInstance;
    component.instrumentId = 2; component.quantity = 10;
    expect(component.estimatedCommission()).toBe(2.5);
    expect(component.estimatedTotal()).toBe(1002.5);
  });
  it('trimite STOP-LIMIT cu prag, limită și valabilitate', () => {
    const component = fixture.componentInstance;
    component.accountId = 1; component.instrumentId = 2; component.orderType = 'STOP_LIMIT'; component.stopPrice = 105; component.limitPrice = 107; component.timeInForce = 'DAY';
    expect((component as any).request()).toEqual(jasmine.objectContaining({ orderType: 'STOP_LIMIT', stopPrice: 105, limitPrice: 107, timeInForce: 'DAY' }));
  });
});
