import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Account, AdminAccount, AdminCustomer, AdminOverview, AdminUser, BrokerNotification, CashBalance, CashTransaction, CurrencyExchangeQuote, CurrencyPortfolioValue, CustomerNotification, CustomerProfile, DisplayExchangeRate, PortfolioHistoryPoint, Position, Instrument, Order } from './models';
@Injectable({ providedIn: 'root' })
export class ApiService {
  private url = 'https://localhost:7103/api';
  constructor(private http: HttpClient) { }
  private get headers() {
    return { Authorization: `Bearer ${localStorage.getItem('brokerage_token')}` };
  }
  login(email: string, password: string) {
    return this.http.post<{ token: string; role: string }>(`${this.url}/auth/login`, { email, password });
  }
  register(customer: { firstName: string; lastName: string; email: string; password: string; documentType: string | null }) {
    return this.http.post(`${this.url}/registration`, customer);
  }
  registerForAdmin(customer: { firstName: string; lastName: string; email: string; password: string; documentType: string | null }) {
    return this.http.post(`${this.url}/registration/admin`, customer, { headers: this.headers });
  }
  adminCustomers() { return this.http.get<AdminCustomer[]>(`${this.url}/admin/customers`, { headers: this.headers }); }
  adminOverview() { return this.http.get<AdminOverview>(`${this.url}/admin/overview`, { headers: this.headers }); }
  adminUsers() { return this.http.get<AdminUser[]>(`${this.url}/admin/users`, { headers: this.headers }); }
  updateAdminUserStatus(id:string,isActive:boolean){return this.http.post(`${this.url}/admin/users/${id}/status`,{isActive},{headers:this.headers});}
  resetAdminUserPassword(id:string,newPassword:string){return this.http.post(`${this.url}/admin/users/${id}/reset-password`,{newPassword},{headers:this.headers});}
  createAdminUser(user:{email:string;password:string;role:string}){return this.http.post(`${this.url}/admin/users`,user,{headers:this.headers});}
  accessAudit(){return this.http.get<any[]>(`${this.url}/admin/access-audit`,{headers:this.headers});}
  adminAccounts(){return this.http.get<AdminAccount[]>(`${this.url}/admin/accounts`,{headers:this.headers});}
  updateAdminAccountStatus(id:number,status:string,reason:string){return this.http.post(`${this.url}/admin/accounts/${id}/status`,{status,reason},{headers:this.headers});}
  openAdminCashAccount(accountId:number,currency:string){return this.http.post(`${this.url}/admin/accounts/${accountId}/cash-accounts`,{currency},{headers:this.headers});}
  updateCustomerStatus(customerId: number, status: string) { return this.http.post(`${this.url}/admin/customers/${customerId}/status`, { status }, { headers: this.headers }); }
  adminCustomerOverview(customerId: number) { return this.http.get<any>(`${this.url}/admin/customers/${customerId}/overview`, { headers: this.headers }); }
  accounts() {
    return this.http.get<Account[]>(`${this.url}/accounts`, { headers: this.headers });
  }
  cash(id: number) {
    return this.http.get<CashBalance[]>(`${this.url}/accounts/${id}/cash`, {
      headers: this.headers,
    });
  }
  portfolio(id: number) {
    return this.http.get<Position[]>(`${this.url}/accounts/${id}/portfolio`, {
      headers: this.headers,
    });
  }
  instruments() {
    return this.http.get<Instrument[]>(`${this.url}/instruments`, { headers: this.headers });
  }
  orders() {
    return this.http.get<Order[]>(`${this.url}/orders`, { headers: this.headers });
  }
  brokerOrderHistory() {
    return this.http.get<Order[]>(`${this.url}/broker/orders/history`, { headers: this.headers });
  }
  cancelOrder(orderId: number) {
    return this.http.post(`${this.url}/orders/${orderId}/cancel`, {}, { headers: this.headers });
  }
  createOrder(order: unknown) {
    return this.http.post<{ orderId: number; status: string }>(`${this.url}/orders`, order, {
      headers: this.headers,
    });
  }
  deposit(cashAccountId: number, amount: number, description: string) {
    return this.http.post(`${this.url}/cash-accounts/${cashAccountId}/deposits`, { amount, description: description || null }, { headers: this.headers });
  }
  withdraw(cashAccountId: number, amount: number, description: string) {
    return this.http.post(`${this.url}/cash-accounts/${cashAccountId}/withdrawals`, { amount, description: description || null }, { headers: this.headers });
  }
  cashTransactions(cashAccountId: number) {
    return this.http.get<CashTransaction[]>(`${this.url}/cash-accounts/${cashAccountId}/transactions`, { headers: this.headers });
  }
  portfolioHistory(from: string, to: string) {
    return this.http.get<PortfolioHistoryPoint[]>(`${this.url}/accounts/history?from=${encodeURIComponent(from)}&to=${encodeURIComponent(to)}`, { headers: this.headers });
  }
  profile() {
    return this.http.get<CustomerProfile>(`${this.url}/profile`, { headers: this.headers });
  }
  notifications() {
    return this.http.get<CustomerNotification[]>(`${this.url}/notifications`, { headers: this.headers });
  }
  markNotificationRead(notificationId: number) {
    return this.http.post(`${this.url}/notifications/${notificationId}/read`, {}, { headers: this.headers });
  }
  markAllNotificationsRead() {
    return this.http.post(`${this.url}/notifications/read-all`, {}, { headers: this.headers });
  }
  brokerNotifications() {
    return this.http.get<BrokerNotification[]>(`${this.url}/broker/notifications`, { headers: this.headers });
  }
  markBrokerNotificationRead(notificationId: number) {
    return this.http.post(`${this.url}/broker/notifications/${notificationId}/read`, {}, { headers: this.headers });
  }
  markAllBrokerNotificationsRead() {
    return this.http.post(`${this.url}/broker/notifications/read-all`, {}, { headers: this.headers });
  }
  exchangeRate(sourceCashAccountId: number, targetCashAccountId: number) {
    return this.http.get<CurrencyExchangeQuote>(`${this.url}/cash-accounts/exchange-rate?sourceCashAccountId=${sourceCashAccountId}&targetCashAccountId=${targetCashAccountId}`, { headers: this.headers });
  }
  exchange(sourceCashAccountId: number, targetCashAccountId: number, sourceAmount: number) {
    return this.http.post(`${this.url}/cash-accounts/exchange`, { sourceCashAccountId, targetCashAccountId, sourceAmount }, { headers: this.headers });
  }
  displayExchangeRates() {
    return this.http.get<DisplayExchangeRate[]>(`${this.url}/exchange-rates/display`, { headers: this.headers });
  }
  portfolioValueByCurrency() {
    return this.http.get<CurrencyPortfolioValue[]>(`${this.url}/accounts/valuation-by-currency`, { headers: this.headers });
  }
  openCashAccount(accountId: number, currency: string) {
    return this.http.post(`${this.url}/accounts/${accountId}/cash-accounts`, { currency }, { headers: this.headers });
  }
}
