import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideZonelessChangeDetection } from '@angular/core';
import { AdminCustomersComponent } from './admin-customers.component';

describe('AdminCustomersComponent', () => {
  let fixture: ComponentFixture<AdminCustomersComponent>;
  beforeEach(async () => {
    await TestBed.configureTestingModule({ providers: [provideZonelessChangeDetection()], imports: [AdminCustomersComponent] }).compileComponents();
    fixture = TestBed.createComponent(AdminCustomersComponent);
    fixture.componentRef.setInput('customers', [
      { customerId: 1, firstName: 'Ana', lastName: 'Pop', email: 'ana@example.test', customerStatus: 'Active', kycStatus: 'Approved', accountsCount: 1, accountStatus: 'Active' },
      { customerId: 2, firstName: 'Mihai', lastName: 'Ionescu', email: 'mihai@example.test', customerStatus: 'Blocked', kycStatus: 'Rejected', accountsCount: 0, accountStatus: null },
    ]);
    fixture.detectChanges();
  });
  it('filtrează clienții după căutare și stare', () => {
    const component = fixture.componentInstance;
    component.query = 'ana'; component.status = 'Active';
    expect(component.filtered().map(item => item.email)).toEqual(['ana@example.test']);
  });
  it('deschide și închide pop-up-ul de creare client', () => {
    const component = fixture.componentInstance;
    expect(component.createOpen()).toBeFalse();
    component.createOpen.set(true);
    expect(component.createOpen()).toBeTrue();
    component.resetFilters();
    expect(component.status).toBe('ALL');
  });
});
