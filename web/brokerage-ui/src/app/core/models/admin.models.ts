export type CreateOrderRequest = {
  accountId: number;
  instrumentId: number;
  side: 'BUY' | 'SELL';
  orderType: 'MARKET' | 'LIMIT' | 'STOP' | 'STOP_LIMIT';
  quantity: number;
  limitPrice: number | null;
  stopPrice: number | null;
  timeInForce: 'DAY' | 'DATE' | 'GTC';
  expiresAt: string | null;
};

export type OrderEstimate = {
  currency: string;
  price: number;
  quoteDate: string;
  orderValue: number;
  commission: number;
  requiredAmount: number;
  availableAmount: number;
  shortfall: number;
  canSubmit: boolean;
  reason: string | null;
};

export type KycAuditEntry = {
  auditLogId: number;
  action: string;
  changedBy: string;
  changedAt: string;
  oldValues: string | null;
  newValues: string | null;
};

export type AccessAuditEntry = {
  accessAuditLogId: number;
  action: string;
  changedBy: string;
  changedAt: string;
  details: string | null;
};

export type OrderAuditEntry = {
  orderActivityLogId: number;
  orderId: number | null;
  activity: string;
  details: string | null;
  changedBy: string;
  changedAt: string;
};

export type AdminCustomerOverview = {
  customerId: number;
  firstName: string;
  lastName: string;
  email: string;
  status: string;
  accounts: AdminAccountOverview[];
  cash: AdminCashBalance[];
  positions: AdminPosition[];
};

export type AdminAccountOverview = {
  accountId: number;
  accountNumber: string;
  currency: string;
  status: string;
};

export type AdminCashBalance = {
  accountId: number;
  cashAccountId?: number;
  currency: string;
  availableBalance: number;
  blockedBalance: number;
};

export type AdminPosition = {
  symbol: string;
  instrumentName: string;
  currency: string;
  quantity: number;
  averagePrice: number;
};

export type KycRecord = {
  kycId: number;
  customerId: number;
  firstName: string;
  lastName: string;
  email: string;
  customerStatus: string;
  status: 'Pending' | 'Approved' | 'Rejected' | string;
  documentType: string;
  createdAt: string;
  updatedAt: string | null;
  rejectionReason: string | null;
};

export type BrokerExecution = {
  executionId: number;
  orderId: number;
  symbol: string;
  side: string;
  executedQuantity: number;
  executionPrice: number;
  tradeCurrency: string;
  commissionReporting: number;
  exchangeRateToReporting: number;
  exchangeRateDate: string;
  tradeValueReporting: number;
  executedAt: string;
};

export type BrokerOrderDetails = {
  orderId: number;
  symbol: string;
  instrumentName: string;
  side: string;
  orderType: string;
  quantity: number;
  limitPrice: number | null;
  status: string;
  createdAt: string;
  firstName: string;
  lastName: string;
  email: string;
  accountNumber: string;
  currency: string;
  availableCash: number;
  blockedCash: number;
  positionQuantity: number;
  averagePrice: number;
  executedQuantity: number;
  marketPrice: number | null;
  quoteDate: string | null;
};

export type AdminAiResponse = {
  answer: string;
  generatedAtUtc: string;
  disclaimer: string;
};

export type BrokerIntelligentAlert = {
  orderId: number;
  symbol: string;
  severity: 'High' | 'Medium' | string;
  title: string;
  reason: string;
  suggestedAction: string;
};
