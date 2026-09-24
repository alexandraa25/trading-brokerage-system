import { DatePipe } from '@angular/common';
import { Component, computed, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { LoginComponent } from './features/login/login.component';
import { PortfolioSummaryComponent } from './features/dashboard/portfolio/portfolio-summary.component';
import { CashBalancesComponent } from './features/dashboard/cash/cash-balances.component';
import { PositionsTableComponent } from './features/dashboard/portfolio/positions-table.component';
import { OrderFormComponent } from './features/dashboard/trading/order-form.component';
import { OrdersHistoryComponent } from './features/dashboard/trading/orders-history.component';
import { InstrumentsListComponent } from './features/dashboard/trading/instruments-list.component';
import { AccountsListComponent } from './features/dashboard/portfolio/accounts-list.component';
import { PortfolioChartComponent } from './features/dashboard/portfolio/portfolio-chart.component';
import { BrokerPanelComponent } from './features/dashboard/broker/broker-panel.component';
import { BrokerAlertsComponent } from './features/dashboard/broker/broker-alerts.component';
import { BrokerExchangeRatesComponent } from './features/dashboard/broker/broker-exchange-rates.component';
import { BrokerSummaryComponent } from './features/dashboard/broker/broker-summary.component';
import { BrokerOrderDetailsComponent } from './features/dashboard/broker/broker-order-details.component';
import { DepositFormComponent } from './features/dashboard/cash/deposit-form.component';
import { CashHistoryComponent } from './features/dashboard/cash/cash-history.component';
import { WithdrawalFormComponent } from './features/dashboard/cash/withdrawal-form.component';
import { NotificationPanelComponent } from './shared/components/notification-panel.component';
import { CurrencyExchangeFormComponent } from './features/dashboard/cash/currency-exchange-form.component';
import { PortfolioCurrencyFilterComponent } from './features/dashboard/portfolio/portfolio-currency-filter.component';
import { ProfileKycComponent } from './features/dashboard/profile/profile-kyc.component';
import { BrokerExecutionsComponent } from './features/dashboard/broker/broker-executions.component';
import { AdminKycComponent } from './features/admin/admin-kyc.component';
import { AdminAuditComponent } from './features/admin/admin-audit.component';
import { KycAuditEntry } from './core/models/admin.models';
import { AdminCustomersComponent } from './features/admin/admin-customers.component';
import { AdminOverviewComponent } from './features/admin/admin-overview.component';
import { AdminUsersComponent } from './features/admin/admin-users.component';
import { AdminAccountsComponent } from './features/admin/admin-accounts.component';
import { AdminAnalyticsComponent } from './features/admin/admin-analytics.component';
import { AdminPowerBiComponent } from './features/admin/admin-powerbi.component';
import { powerBiConfig } from './core/config/powerbi.config';
import { AdminAccount, AdminAnalytics, AdminCustomer, AdminOverview, AdminUser, BrokerNotification, CashTransaction, CurrencyExchangeQuote, CurrencyPortfolioValue, CustomerNotification, CustomerProfile, DisplayExchangeRate, Instrument, Order, PortfolioHistoryPoint } from './core/models';
import { ApiService } from './core/api.service';
import { CashBalance, PortfolioPosition, PortfolioValuation, TradingAccount } from './core/models/dashboard.models';
import { AdminCustomerOverview, BrokerExecution, BrokerOrderDetails, CreateOrderRequest, KycRecord } from './core/models/admin.models';
import { CustomerDashboardService } from './core/services/customer-dashboard.service';
import { BrokerDashboardService } from './core/services/broker-dashboard.service';
import { AdminDashboardService } from './core/services/admin-dashboard.service';

@Component({ selector: 'app-root', imports: [DatePipe, LoginComponent, PortfolioSummaryComponent, CashBalancesComponent, PositionsTableComponent, OrderFormComponent, OrdersHistoryComponent, InstrumentsListComponent, AccountsListComponent, PortfolioChartComponent, BrokerPanelComponent, BrokerAlertsComponent, BrokerExchangeRatesComponent, BrokerSummaryComponent, BrokerOrderDetailsComponent, DepositFormComponent, WithdrawalFormComponent, CurrencyExchangeFormComponent, PortfolioCurrencyFilterComponent, CashHistoryComponent, ProfileKycComponent, NotificationPanelComponent, BrokerExecutionsComponent, AdminKycComponent, AdminAuditComponent, AdminCustomersComponent, AdminOverviewComponent, AdminUsersComponent, AdminAccountsComponent, AdminAnalyticsComponent, AdminPowerBiComponent], templateUrl: './app.html', styleUrl: './app.scss' })
export class App {
  email = 'customer.demo@brokerage.local';
  password = 'DemoCustomer!2026';
  loading = signal(false);
  error = signal('');
  loggedIn = signal(!!localStorage.getItem('brokerage_token'));
  accounts = signal<TradingAccount[]>([]);
  cashBalances = signal<CashBalance[]>([]);
  cashTransactions = signal<CashTransaction[]>([]);
  portfolioHistory = signal<PortfolioHistoryPoint[]>([]);
  profile = signal<CustomerProfile | null>(null);
  notifications = signal<CustomerNotification[]>([]);
  brokerNotifications = signal<BrokerNotification[]>([]);
  notificationsOpen = signal(false);
  exchangeQuote = signal<CurrencyExchangeQuote | null>(null);
  displayRates = signal<DisplayExchangeRate[]>([]);
  displayCurrency = signal('EUR');
  portfolioCurrencyValues = signal<CurrencyPortfolioValue[]>([]);
  portfolioCurrencyFilter = signal('ALL');
  displayMultiplier = computed(() => 1 / (this.displayRates().find(rate => rate.currency === this.displayCurrency())?.midRate ?? 1));
  displayTotal = computed(() => this.totalValueEur() * this.displayMultiplier());
  displayInvested = computed(() => this.investedValueEur() * this.displayMultiplier());
  displayProfit = computed(() => this.profitLossEur() * this.displayMultiplier());
  displayHistory = computed(() => this.portfolioHistory().map(point => ({ ...point, investedValueEur: point.investedValueEur * this.displayMultiplier(), positionsValueEur: point.positionsValueEur * this.displayMultiplier(), cashValueEur: point.cashValueEur * this.displayMultiplier(), totalValueEur: point.totalValueEur * this.displayMultiplier() })));
  selectedCurrencyPortfolio = computed(() => this.portfolioCurrencyValues().find(item => item.currency === this.portfolioCurrencyFilter()) ?? null);
  portfolioCurrencies = computed(() => this.portfolioCurrencyValues().map(item => item.currency));
  overviewCurrency = computed(() => this.selectedCurrencyPortfolio()?.currency ?? this.displayCurrency());
  overviewTotal = computed(() => this.selectedCurrencyPortfolio()?.totalValue ?? this.displayTotal());
  overviewInvested = computed(() => this.selectedCurrencyPortfolio()?.investedValue ?? this.displayInvested());
  overviewProfit = computed(() => this.selectedCurrencyPortfolio()?.profitLoss ?? this.displayProfit());
  overviewPercent = computed(() => { const selected = this.selectedCurrencyPortfolio(); return selected ? (selected.investedValue === 0 ? 0 : selected.profitLoss / selected.investedValue * 100) : this.profitLossPercent(); });
  filteredBalances = computed(() => this.portfolioCurrencyFilter() === 'ALL' ? this.cashBalances() : this.cashBalances().filter(item => item.currency === this.portfolioCurrencyFilter()));
  filteredPositions = computed(() => this.portfolioCurrencyFilter() === 'ALL' ? this.positions() : this.positions().filter(item => item.currency === this.portfolioCurrencyFilter()));
  positions = signal<PortfolioPosition[]>([]);
  instruments = signal<Instrument[]>([]);
  orders = signal<Order[]>([]);
  brokerOrderHistory = signal<Order[]>([]);
  brokerExecutions = signal<BrokerExecution[]>([]);
  brokerUpdatedAt = signal<Date | null>(null);
  brokerDisplayCurrency = signal('EUR');
  brokerDisplayMultiplier = computed(() => 1 / (this.displayRates().find(rate => rate.currency === this.brokerDisplayCurrency())?.midRate ?? 1));
  brokerOrderDetails = signal<BrokerOrderDetails | null>(null);
  kycRecords = signal<KycRecord[]>([]);
  kycAudit = signal<KycAuditEntry[]>([]);
  adminCustomers = signal<AdminCustomer[]>([]);
  adminCustomerOverview = signal<AdminCustomerOverview | null>(null);
  adminOverview = signal<AdminOverview | null>(null);
  adminAnalytics = signal<AdminAnalytics | null>(null);
  adminUsers = signal<AdminUser[]>([]);
  adminAccounts = signal<AdminAccount[]>([]);
  adminAccountDetails = signal<{ accountId: number; cash: CashBalance[]; positions: PortfolioPosition[] } | null>(null);
  totalValueEur = signal(0);
  investedValueEur = signal(0);
  profitLossEur = signal(0);
  profitLossPercent = signal(0);
  orderMessage = signal('');
  activeTab = signal<'overview' | 'market' | 'trade' | 'cash' | 'orders' | 'profile' | 'broker'>('overview');
  isBroker = signal(localStorage.getItem('brokerage_role') === 'Broker');
  isAdmin = signal(localStorage.getItem('brokerage_role') === 'Administrator');
  brokerTab = signal<'overview' | 'orders' | 'executions' | 'rates'>('overview');
  adminTab = signal<'overview' | 'analytics' | 'powerbi' | 'kyc' | 'customers' | 'accounts' | 'users' | 'audit'>('overview');
  powerBiReportUrl = powerBiConfig.reportUrl;
  order: CreateOrderRequest = { accountId: 0, instrumentId: 0, side: 'BUY', orderType: 'MARKET', quantity: 1, limitPrice: null };

  refreshTimer?: ReturnType<typeof setInterval>;
  notificationTimer?: ReturnType<typeof setInterval>;
  alertedStaleOrderIds = new Set<number>();

  constructor(private readonly http: HttpClient, private readonly api: ApiService, private readonly customerDashboard: CustomerDashboardService, private readonly brokerDashboard: BrokerDashboardService, private readonly adminDashboard: AdminDashboardService) { if (this.loggedIn()) { if (this.isAdmin()) this.loadAdminData(); else { this.loadAccounts(); if (this.isBroker()) this.startBrokerRefresh(); else this.startNotificationRefresh(); } } }

  login() {
    this.loading.set(true); this.error.set('');
    this.http.post<{ token: string }>('https://localhost:7103/api/auth/login', { email: this.email, password: this.password }).subscribe({
      next: response => { localStorage.setItem('brokerage_token', response.token); this.loggedIn.set(true); this.loading.set(false); this.loadAccounts(); },
      error: () => { this.error.set('Date invalide sau API-ul nu rulează.'); this.loading.set(false); }
    });
  }

  onAuthenticated() { const role = localStorage.getItem('brokerage_role'); const broker = role === 'Broker'; const admin = role === 'Administrator'; this.isBroker.set(broker); this.isAdmin.set(admin); this.activeTab.set(broker ? 'broker' : 'overview'); this.loggedIn.set(true); if (admin) this.loadAdminData(); else this.loadAccounts(); if (broker) this.startBrokerRefresh(); else if (!admin) this.startNotificationRefresh(); }

  loadAdminData() {
    this.adminDashboard.loadDashboard().subscribe({
      next: data => {
        this.kycRecords.set(data.kyc as KycRecord[]); this.kycAudit.set(data.audit as KycAuditEntry[]);
        this.adminCustomers.set(data.customers); this.adminOverview.set(data.overview); this.adminAnalytics.set(data.analytics);
        this.adminUsers.set(data.users); this.adminAccounts.set(data.accounts);
      },
      error: () => this.orderMessage.set('Datele administrative nu au putut fi încărcate. Repornește API-ul și autentifică-te din nou.')
    });
  }
  updateKycStatus(change: { kycId: number; status: 'Approved' | 'Rejected'; rejectionReason?: string }) {
    const headers = { Authorization: `Bearer ${localStorage.getItem('brokerage_token')}` };
    this.http.post(`https://localhost:7103/api/admin/kyc/${change.kycId}/status`, { status: change.status, rejectionReason: change.rejectionReason ?? null }, { headers }).subscribe({ next: () => { this.orderMessage.set(change.status === 'Approved' ? 'Dosarul KYC a fost aprobat.' : 'Dosarul KYC a fost respins.'); this.loadAdminData(); }, error: () => this.orderMessage.set('Starea dosarului KYC nu a putut fi actualizată.') });
  }

  createCustomerForAdmin(customer: { firstName: string; lastName: string; email: string; password: string; documentType: string }) {
    this.api.registerForAdmin(customer).subscribe({ next: () => { this.orderMessage.set('Clientul, contul EUR și dosarul KYC au fost create.'); this.loadAdminData(); }, error: error => this.orderMessage.set(error.error?.detail ?? 'Clientul nu a putut fi creat.') });
  }

  updateCustomerStatus(change: { customerId: number; status: string }) {
    this.api.updateCustomerStatus(change.customerId, change.status).subscribe({ next: () => { this.orderMessage.set('Starea clientului a fost actualizată.'); this.loadAdminData(); }, error: error => this.orderMessage.set(error.error?.detail ?? 'Starea clientului nu a putut fi actualizată.') });
  }

  loadAdminCustomerOverview(customerId: number) {
    this.api.adminCustomerOverview(customerId).subscribe({ next: item => this.adminCustomerOverview.set(item), error: () => this.orderMessage.set('Detaliile clientului nu au putut fi încărcate.') });
  }
  loadAdminAnalytics(days = 30) { this.api.adminAnalytics(days).subscribe({ next: item => this.adminAnalytics.set(item), error: () => this.adminAnalytics.set(null) }); }
  updateAdminUserStatus(change:{id:string;isActive:boolean}) { this.api.updateAdminUserStatus(change.id,change.isActive).subscribe({next:()=>{this.orderMessage.set('Starea utilizatorului a fost actualizată.');this.loadAdminData();}}); }
  resetAdminUserPassword(change:{id:string;password:string}) { this.api.resetAdminUserPassword(change.id,change.password).subscribe({next:()=>this.orderMessage.set('Parola utilizatorului a fost resetată.'),error:()=>this.orderMessage.set('Parola nu a putut fi resetată.')}); }
  createAdminUser(user:{email:string;password:string;role:string}) { this.api.createAdminUser(user).subscribe({next:()=>{this.orderMessage.set('Utilizatorul a fost creat.');this.loadAdminData();},error:error=>this.orderMessage.set(error.error?.detail??'Utilizatorul nu a putut fi creat.')}); }
  updateAdminAccountStatus(change:{id:number;status:string;reason:string}) { this.api.updateAdminAccountStatus(change.id,change.status,change.reason).subscribe({next:()=>{this.orderMessage.set('Starea contului a fost actualizată.');this.loadAdminData();},error:error=>this.orderMessage.set(error.error?.detail??'Starea contului nu a putut fi actualizată.')}); }
  openAdminCashAccount(change:{accountId:number;currency:string}) { this.api.openAdminCashAccount(change.accountId,change.currency).subscribe({next:()=>this.orderMessage.set(`Contul de numerar în ${change.currency} a fost deschis.`),error:error=>this.orderMessage.set(error.error?.detail??'Contul de numerar nu a putut fi deschis.')}); }
  loadAdminAccountDetails(accountId:number) { const headers={Authorization:`Bearer ${localStorage.getItem('brokerage_token')}`}; this.http.get<CashBalance[]>(`https://localhost:7103/api/accounts/${accountId}/cash`,{headers}).subscribe(cash=>this.http.get<PortfolioPosition[]>(`https://localhost:7103/api/accounts/${accountId}/portfolio`,{headers}).subscribe(positions=>this.adminAccountDetails.set({accountId,cash,positions}))); }
  exportAdminCustomers() { this.downloadCsv('clienti.csv',['ID','Prenume','Nume','Email','Stare','KYC','Conturi'],this.adminCustomers().map(x=>[x.customerId,x.firstName,x.lastName,x.email,x.customerStatus,x.kycStatus,x.accountsCount])); }
  exportKyc() { this.downloadCsv('dosare-kyc.csv',['ID KYC','Client','Email','Stare','Document','Creat la'],this.kycRecords().map(x=>[x.kycId,`${x.firstName} ${x.lastName}`,x.email,x.status,x.documentType,x.createdAt])); }
  exportAudit() { this.downloadCsv('jurnal-audit-kyc.csv',['ID','Acțiune','Utilizator','Moment','Înainte','După'],this.kycAudit().map(x=>[x.auditLogId,x.action,x.changedBy,x.changedAt,x.oldValues??'',x.newValues??''])); }

  loadAccounts() {
    if (this.isBroker()) { this.loadBrokerData(); return; }
    this.cashBalances.set([]); this.cashTransactions.set([]); this.positions.set([]); this.exchangeQuote.set(null);
    const to = this.dateValue(new Date()); const fromDate = new Date(); fromDate.setDate(fromDate.getDate() - 6);
    this.customerDashboard.loadOverview(this.dateValue(fromDate), to).subscribe({
      next: data => {
        const accounts = data.accounts as TradingAccount[];
        this.accounts.set(accounts); this.instruments.set(data.instruments); this.orders.set(data.orders); this.profile.set(data.profile);
        this.displayRates.set(data.rates); this.portfolioCurrencyValues.set(data.portfolioCurrencies); this.portfolioHistory.set(data.history); this.notifications.set(data.notifications);
        this.totalValueEur.set(0); this.investedValueEur.set(0); this.profitLossEur.set(0); this.order.accountId = accounts[0]?.accountId ?? 0; this.order.instrumentId = data.instruments[0]?.instrumentId ?? 0;
        accounts.forEach(account => { this.loadAccountDetails(account.accountId); this.loadValuation(account.accountId); });
      },
      error: () => this.error.set('Nu s-au putut încărca datele portofoliului.')
    });
  }
  loadNotifications() { this.api.notifications().subscribe({ next: items => this.notifications.set(items), error: () => this.notifications.set([]) }); }
  loadBrokerNotifications() { this.api.brokerNotifications().subscribe({ next: items => this.brokerNotifications.set(items), error: () => this.brokerNotifications.set([]) }); }
  unreadNotifications() { return this.notifications().filter(item => !item.isRead).length; }
  toggleNotifications() { this.notificationsOpen.update(value => !value); }
  markNotificationRead(notificationId: number) { this.api.markNotificationRead(notificationId).subscribe(() => this.notifications.update(items => items.map(item => item.customerNotificationId === notificationId ? { ...item, isRead: true } : item))); }
  markAllNotificationsRead() { this.api.markAllNotificationsRead().subscribe(() => this.notifications.update(items => items.map(item => ({ ...item, isRead: true })))); }
  unreadBrokerNotifications() { return this.brokerNotifications().filter(item => !item.isRead).length; }
  markBrokerNotificationRead(notificationId: number) { this.api.markBrokerNotificationRead(notificationId).subscribe(() => this.brokerNotifications.update(items => items.map(item => item.brokerNotificationId === notificationId ? { ...item, isRead: true } : item))); }
  markAllBrokerNotificationsRead() { this.api.markAllBrokerNotificationsRead().subscribe(() => this.brokerNotifications.update(items => items.map(item => ({ ...item, isRead: true })))); }
  startNotificationRefresh() { if (this.notificationTimer) clearInterval(this.notificationTimer); this.notificationTimer = setInterval(() => this.loadNotifications(), 30000); }
  selectDisplayCurrency(currency: string) { this.displayCurrency.set(currency); }
  selectPortfolioCurrency(currency: string) { this.portfolioCurrencyFilter.set(currency); }

  loadPortfolioHistory(period?: { from: string; to: string }) {
    const to = period?.to ?? this.dateValue(new Date());
    const fromDate = new Date(); fromDate.setDate(fromDate.getDate() - 6);
    const from = period?.from ?? this.dateValue(fromDate);
    this.api.portfolioHistory(from, to).subscribe({ next: points => this.portfolioHistory.set(points), error: () => this.portfolioHistory.set([]) });
  }

  private dateValue(value: Date) { return value.toISOString().slice(0, 10); }

  loadBrokerData() {
    const knownOrderIds = new Set(this.orders().map(order => order.orderId));
    this.brokerDashboard.loadDashboard().subscribe(data => {
      const hasNewOrders = knownOrderIds.size > 0 && data.orders.some(order => !knownOrderIds.has(order.orderId));
      const staleOrderIds = data.orders.filter(order => (order.status === 'Pending' || order.status === 'PartiallyExecuted') && Date.now() - new Date(order.createdAt).getTime() >= 15 * 60 * 1000).map(order => order.orderId);
      const newlyStale = staleOrderIds.filter(id => !this.alertedStaleOrderIds.has(id)); this.alertedStaleOrderIds = new Set(staleOrderIds);
      if (hasNewOrders) this.orderMessage.set('Au apărut ordine noi în lista brokerului.'); else if (newlyStale.length) this.orderMessage.set(`${newlyStale.length} ordin(e) activ(e) necesită atenție.`);
      this.orders.set(data.orders); this.brokerExecutions.set(data.executions as BrokerExecution[]); this.brokerOrderHistory.set(data.history); this.displayRates.set(data.rates); this.brokerNotifications.set(data.notifications); this.brokerUpdatedAt.set(new Date());
    });
  }
  loadBrokerOrderDetails(orderId: number) {
    const headers = { Authorization: `Bearer ${localStorage.getItem('brokerage_token')}` };
    this.http.get<BrokerOrderDetails>(`https://localhost:7103/api/broker/orders/${orderId}/details`, { headers }).subscribe({ next: detail => this.brokerOrderDetails.set(detail), error: () => this.orderMessage.set('Detaliile ordinului nu au putut fi încărcate.') });
  }

  openBrokerOrder(orderId: number): void {
    this.brokerTab.set('orders');
    this.loadBrokerOrderDetails(orderId);
  }

  startBrokerRefresh() {
    if (this.refreshTimer) clearInterval(this.refreshTimer);
    this.refreshTimer = setInterval(() => this.loadBrokerData(), 25000);
  }

  refreshBrokerData(): void {
    this.loadBrokerData();
    this.orderMessage.set('Lista ordinelor și istoricul execuțiilor au fost actualizate.');
  }

  selectBrokerDisplayCurrency(currency: string): void {
    this.brokerDisplayCurrency.set(currency);
  }

  exportBrokerOrders(): void {
    const rows = this.brokerOrderHistory().map(order => [
      order.orderId, order.symbol, order.side, order.orderType, order.quantity,
      order.limitPrice ?? '', order.status, this.exportDate(order.createdAt)
    ]);
    this.downloadCsv('istoric-ordine-broker.csv', ['ID ordin', 'Simbol', 'Sens', 'Tip', 'Cantitate', 'Preț limită', 'Stare', 'Creat la'], rows);
  }

  exportBrokerExecutions(): void {
    const rows = this.brokerExecutions().map(execution => [
      execution.executionId, execution.orderId, execution.symbol, execution.side,
      execution.executedQuantity, execution.executionPrice, execution.tradeCurrency,
      execution.commissionReporting, execution.exchangeRateToReporting,
      execution.exchangeRateDate, execution.tradeValueReporting, this.exportDate(execution.executedAt)
    ]);
    this.downloadCsv('istoric-executii-broker.csv', ['ID execuție', 'ID ordin', 'Simbol', 'Sens', 'Cantitate', 'Preț', 'Monedă', 'Comision EUR', 'Curs BCE', 'Data cursului', 'Valoare EUR', 'Executat la'], rows);
  }

  private exportDate(value: string): string {
    return new Date(value).toLocaleString('ro-RO');
  }

  private downloadCsv(fileName: string, headers: string[], rows: unknown[][]): void {
    const escape = (value: unknown) => `"${String(value ?? '').replaceAll('"', '""')}"`;
    const content = [headers, ...rows].map(row => row.map(escape).join(';')).join('\r\n');
    const link = document.createElement('a');
    link.href = URL.createObjectURL(new Blob([`\ufeff${content}`], { type: 'text/csv;charset=utf-8;' }));
    link.download = fileName;
    link.click();
    URL.revokeObjectURL(link.href);
  }

  loadAccountDetails(accountId: number) {
    const headers = { Authorization: `Bearer ${localStorage.getItem('brokerage_token')}` };
    this.http.get<CashBalance[]>(`https://localhost:7103/api/accounts/${accountId}/cash`, { headers }).subscribe(items => {
      this.cashBalances.update(current => [...current, ...items]);
      items.forEach(item => this.api.cashTransactions(item.cashAccountId).subscribe(transactions => this.cashTransactions.update(current => [...current, ...transactions])));
    });
    this.http.get<PortfolioPosition[]>(`https://localhost:7103/api/accounts/${accountId}/portfolio`, { headers }).subscribe(items => this.positions.update(current => [...current, ...items]));
  }

  loadValuation(accountId: number) {
    const headers = { Authorization: `Bearer ${localStorage.getItem('brokerage_token')}` };
    this.http.get<PortfolioValuation>(`https://localhost:7103/api/accounts/${accountId}/valuation`, { headers })
      .subscribe(item => { this.totalValueEur.update(total => total + item.totalValueEUR); this.investedValueEur.update(total => total + item.investedValueEUR); this.profitLossEur.update(total => total + item.profitLossEUR); this.profitLossPercent.set(this.investedValueEur() === 0 ? 0 : this.profitLossEur() / this.investedValueEur() * 100); });
  }

  createOrder(order: CreateOrderRequest = this.order) {
    this.orderMessage.set(''); const headers = { Authorization: `Bearer ${localStorage.getItem('brokerage_token')}` };
    this.http.post<{ orderId: number; status: string }>('https://localhost:7103/api/orders', order, { headers }).subscribe({ next: result => { this.orderMessage.set(`Ordinul #${result.orderId} a fost creat: ${result.status}.`); this.loadAccounts(); this.activeTab.set('orders'); }, error: () => this.orderMessage.set('Ordinul nu a putut fi creat. Verifică datele introduse.') });
  }

  depositCash(deposit: { cashAccountId: number; amount: number; description: string }) {
    this.orderMessage.set('');
    this.api.deposit(deposit.cashAccountId, deposit.amount, deposit.description).subscribe({ next: () => { this.orderMessage.set('Depunerea a fost înregistrată, iar soldul a fost actualizat.'); this.loadAccounts(); }, error: error => this.orderMessage.set(error.error?.detail ?? 'Depunerea nu a putut fi înregistrată.') });
  }

  openCashAccount(request: { accountId: number; currency: string }) {
    this.orderMessage.set('');
    this.api.openCashAccount(request.accountId, request.currency).subscribe({ next: () => { this.orderMessage.set(`Contul de numerar în ${request.currency} a fost deschis. Poți depune acum în el.`); this.loadAccounts(); }, error: error => this.orderMessage.set(error.error?.detail ?? 'Contul de numerar nu a putut fi deschis.') });
  }

  withdrawCash(withdrawal: { cashAccountId: number; amount: number; description: string }) {
    this.orderMessage.set('');
    this.api.withdraw(withdrawal.cashAccountId, withdrawal.amount, withdrawal.description).subscribe({ next: () => { this.orderMessage.set('Retragerea a fost înregistrată, iar soldul a fost actualizat.'); this.loadAccounts(); }, error: error => this.orderMessage.set(error.error?.detail ?? 'Retragerea nu a putut fi înregistrată.') });
  }

  loadExchangeQuote(selection: { sourceCashAccountId: number; targetCashAccountId: number }) {
    this.exchangeQuote.set(null);
    this.api.exchangeRate(selection.sourceCashAccountId, selection.targetCashAccountId).subscribe({ next: quote => this.exchangeQuote.set(quote), error: error => this.orderMessage.set(error.error?.detail ?? 'Cursul valutar nu a putut fi încărcat.') });
  }

  exchangeCash(exchange: { sourceCashAccountId: number; targetCashAccountId: number; sourceAmount: number }) {
    this.orderMessage.set('');
    this.api.exchange(exchange.sourceCashAccountId, exchange.targetCashAccountId, exchange.sourceAmount).subscribe({ next: () => { this.orderMessage.set('Schimbul valutar a fost înregistrat la cursul BCE afișat.'); this.loadAccounts(); }, error: error => this.orderMessage.set(error.error?.detail ?? 'Schimbul valutar nu a putut fi înregistrat.') });
  }

  cancelOrder(orderId: number) { this.api.cancelOrder(orderId).subscribe({ next: () => this.loadAccounts(), error: () => this.orderMessage.set('Ordinul nu a putut fi anulat.') }); }

  executeOrder(execution: { id: number; quantity: number; price: number }) {
    const headers = { Authorization: `Bearer ${localStorage.getItem('brokerage_token')}` };
    this.http.post(`https://localhost:7103/api/orders/${execution.id}/executions`, { executedQuantity: execution.quantity, executionPrice: execution.price }, { headers }).subscribe({ next: () => { this.orderMessage.set('Ordinul a fost executat.'); this.brokerOrderDetails.set(null); this.loadAccounts(); }, error: error => this.orderMessage.set(error.error?.detail ?? 'Execuția nu a putut fi înregistrată.') });
  }

  rejectBrokerOrder(rejection: { id: number; reason: string }) {
    const headers = { Authorization: `Bearer ${localStorage.getItem('brokerage_token')}` };
    this.http.post(`https://localhost:7103/api/broker/orders/${rejection.id}/reject`, { reason: rejection.reason }, { headers }).subscribe({ next: () => { this.orderMessage.set('Ordinul a fost respins, iar clientul a fost notificat.'); this.brokerOrderDetails.set(null); this.loadBrokerData(); }, error: error => this.orderMessage.set(error.error?.detail ?? 'Ordinul nu a putut fi respins.') });
  }

  logout() { if (this.refreshTimer) clearInterval(this.refreshTimer); if (this.notificationTimer) clearInterval(this.notificationTimer); localStorage.removeItem('brokerage_token'); localStorage.removeItem('brokerage_role'); this.isBroker.set(false); this.isAdmin.set(false); this.accounts.set([]); this.cashBalances.set([]); this.cashTransactions.set([]); this.portfolioHistory.set([]); this.profile.set(null); this.notifications.set([]); this.brokerNotifications.set([]); this.notificationsOpen.set(false); this.exchangeQuote.set(null); this.brokerOrderDetails.set(null); this.brokerOrderHistory.set([]); this.brokerUpdatedAt.set(null); this.alertedStaleOrderIds.clear(); this.positions.set([]); this.loggedIn.set(false); }
}
