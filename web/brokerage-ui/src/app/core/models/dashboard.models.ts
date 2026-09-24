export type TradingAccount = {
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

export type PortfolioPosition = {
  symbol: string;
  instrumentName: string;
  currency: string;
  quantity: number;
  averagePrice: number;
};

export type PortfolioValuation = {
  totalValueEUR: number;
  investedValueEUR: number;
  profitLossEUR: number;
  profitLossPercent: number;
};