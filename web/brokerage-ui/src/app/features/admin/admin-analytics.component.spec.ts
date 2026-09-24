import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideZonelessChangeDetection } from '@angular/core';
import { AdminAnalyticsComponent } from './admin-analytics.component';

describe('AdminAnalyticsComponent', () => {
  let fixture: ComponentFixture<AdminAnalyticsComponent>;
  beforeEach(async () => {
    await TestBed.configureTestingModule({ providers: [provideZonelessChangeDetection()], imports: [AdminAnalyticsComponent] }).compileComponents();
    fixture = TestBed.createComponent(AdminAnalyticsComponent);
    fixture.componentRef.setInput('data', { portfolioValue: 0, netCashFlow: 0, commissions: 0, activeOrders: 0, completedOrders: 0, rejectedOrders: 0, pendingKyc: 0, averageKycDays: 0, days: 7, trend: [{ date: '2026-09-17', value: 100 }, { date: '2026-09-18', value: 110 }] });
    fixture.detectChanges();
  });
  it('calculează puncte diferite pentru o evoluție ascendentă', () => {
    const points = fixture.componentInstance.chartPoints();
    expect(points.length).toBe(2); expect(points[0].y).toBeGreaterThan(points[1].y);
  });
  it('emite perioada aleasă pentru reîncărcare', () => {
    const component = fixture.componentInstance; let selected = 0;
    component.periodChange.subscribe(value => selected = value);
    component.choosePeriod(90);
    expect(component.selectedPeriod()).toBe(90); expect(selected).toBe(90);
  });
});
