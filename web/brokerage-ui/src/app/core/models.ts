export type Account = {
  accountId: number;
  accountNumber: string;
  currency: string;
  status: string;
};
export type CashBalance = {
  cashAccountId: number;
  currency: string;
  availableBalance: number;
  blockedBalance: number;
};
export type CashTransaction = {
  cashTransactionId: number;
  transactionType: string;
  amount: number;
  currency: string;
  referenceType: string | null;
  referenceId: number | null;
  description: string | null;
  createdAt: string;
};
export type PortfolioHistoryPoint = {
  snapshotDate: string;
  investedValueEur: number;
  positionsValueEur: number;
  cashValueEur: number;
  totalValueEur: number;
};
export type CustomerProfile = {
  firstName: string;
  lastName: string;
  email: string;
  customerStatus: string;
  kycStatus: string;
  documentType: string | null;
  kycCreatedAt: string | null;
  verifiedAt: string | null;
  rejectionReason: string | null;
};
export type CustomerNotification = {
  customerNotificationId: number;
  notificationType: string;
  title: string;
  message: string;
  isRead: boolean;
  createdAt: string;
};
export type BrokerNotification = {
  brokerNotificationId: number;
  notificationType: string;
  title: string;
  message: string;
  isRead: boolean;
  createdAt: string;
};
export type AdminCustomer = {
  customerId: number;
  firstName: string;
  lastName: string;
  email: string;
  customerStatus: string;
  kycStatus: string;
  accountsCount: number;
  accountStatus: string | null;
};
export type AdminOverview = {
  activeCustomers: number;
  pendingKyc: number;
  activeOrders: number;
  dailyExecutions: number;
  blockedCustomers: number;
  delayedKyc: number;
  latestRateDate: string | null;
  exchangeRateOutdated: boolean;
};
export type AdminUser = {
  apiUserId: string;
  email: string;
  role: string;
  isActive: boolean;
  createdAt: string;
};
export type AdminAccount = {
  accountId: number;
  accountNumber: string;
  currency: string;
  status: string;
  customerName: string;
  email: string;
};
export type AdminAnalytics = {
  portfolioValue: number;
  netCashFlow: number;
  commissions: number;
  activeOrders: number;
  completedOrders: number;
  rejectedOrders: number;
  pendingKyc: number;
  averageKycDays: number;
  trend: { date: string; value: number }[];
  days: number;
};
export type CurrencyExchangeQuote = {
  sourceCurrency: string;
  targetCurrency: string;
  exchangeRate: number;
  sourceRateDate: string;
  targetRateDate: string;
  rateSource: string;
};
export type DisplayExchangeRate = {
  currency: string;
  midRate: number;
  rateDate: string;
  rateSource: string;
};
export type CurrencyPortfolioValue = {
  currency: string;
  investedValue: number;
  positionsValue: number;
  cashValue: number;
  totalValue: number;
  profitLoss: number;
};
export type Position = {
  symbol: string;
  instrumentName: string;
  currency: string;
  quantity: number;
  averagePrice: number;
};
export type Instrument = {
  instrumentId: number;
  symbol: string;
  instrumentName: string;
  instrumentType: string;
  currency: string;
  marketName: string;
  issuerName: string;
  marketPrice: number | null;
  quoteDate: string | null;
  quoteSource: string | null;
};
export type InstrumentQuotePoint = { quoteDate: string; marketPrice: number };

export type Order = {
  orderId: number;
  symbol: string;
  side: string;
  orderType: string;
  quantity: number;
  limitPrice: number | null;
  stopPrice: number | null;
  originalQuantity: number;
  executedQuantity: number;
  cancelledQuantity: number;
  remainingQuantity: number;
  status: string;
  createdAt: string;
};
