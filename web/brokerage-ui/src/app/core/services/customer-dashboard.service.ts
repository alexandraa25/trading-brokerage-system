import { Injectable } from '@angular/core';
import { forkJoin } from 'rxjs';
import { ApiService } from '../api.service';
import { Instrument, Order, CustomerProfile, DisplayExchangeRate, CurrencyPortfolioValue, PortfolioHistoryPoint } from '../models';
import { CashBalance, PortfolioPosition, PortfolioValuation, TradingAccount } from '../models/dashboard.models';

@Injectable({ providedIn: 'root' })
export class CustomerDashboardService {
  constructor(private readonly api: ApiService) {}

  loadOverview(from: string, to: string) {
    return forkJoin({
      accounts: this.api.accounts() as ReturnType<ApiService['accounts']>,
      instruments: this.api.instruments(), orders: this.api.orders(), profile: this.api.profile(),
      rates: this.api.displayExchangeRates(), portfolioCurrencies: this.api.portfolioValueByCurrency(),
      history: this.api.portfolioHistory(from, to), notifications: this.api.notifications(),
    });
  }
  cash(accountId: number) { return this.api.cash(accountId) as unknown as import('rxjs').Observable<CashBalance[]>; }
  positions(accountId: number) { return this.api.portfolio(accountId) as unknown as import('rxjs').Observable<PortfolioPosition[]>; }
  valuation(accountId: number) { return this.api.valuation(accountId) as unknown as import('rxjs').Observable<PortfolioValuation>; }
}