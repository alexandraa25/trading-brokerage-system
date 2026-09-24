import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideZonelessChangeDetection } from '@angular/core';
import { AdminUsersComponent } from './admin-users.component';

describe('AdminUsersComponent', () => {
  let fixture: ComponentFixture<AdminUsersComponent>;
  beforeEach(async () => {
    await TestBed.configureTestingModule({ providers: [provideZonelessChangeDetection()], imports: [AdminUsersComponent] }).compileComponents();
    fixture = TestBed.createComponent(AdminUsersComponent);
    fixture.componentRef.setInput('users', [
      { apiUserId: '1', email: 'broker@example.test', role: 'Broker', isActive: true, createdAt: '' },
      { apiUserId: '2', email: 'admin@example.test', role: 'Administrator', isActive: false, createdAt: '' },
    ]);
    fixture.detectChanges();
  });
  it('filtrează utilizatorii după rol și stare', () => {
    const component = fixture.componentInstance;
    component.role = 'Broker'; component.active = 'ACTIVE';
    expect(component.filtered().length).toBe(1);
    expect(component.filtered()[0].email).toBe('broker@example.test');
  });
  it('resetează filtrele personalului', () => {
    const component = fixture.componentInstance;
    component.query = 'broker'; component.role = 'Broker'; component.active = 'ACTIVE';
    component.resetFilters();
    expect(component.query).toBe(''); expect(component.role).toBe('ALL'); expect(component.active).toBe('ALL');
  });
});
