#!/usr/bin/env bash
set -euo pipefail

sqlcmd_bin="/opt/mssql-tools18/bin/sqlcmd"
if [[ ! -x "$sqlcmd_bin" ]]; then
  sqlcmd_bin="/opt/mssql-tools/bin/sqlcmd"
fi

if [[ ! -x "$sqlcmd_bin" ]]; then
  echo "Nu a fost găsit sqlcmd în containerul de inițializare." >&2
  exit 1
fi

for attempt in $(seq 1 60); do
  if "$sqlcmd_bin" -S db -U sa -P "$MSSQL_SA_PASSWORD" -C -Q "SELECT 1" >/dev/null 2>&1; then
    break
  fi
  if [[ "$attempt" == "60" ]]; then
    echo "SQL Server nu a devenit disponibil în timpul alocat." >&2
    exit 1
  fi
  sleep 2
done

database_exists=$("$sqlcmd_bin" -S db -U sa -P "$MSSQL_SA_PASSWORD" -C -h -1 -W -Q "SET NOCOUNT ON; SELECT CASE WHEN DB_ID('BrokerageDB') IS NULL THEN 0 ELSE 1 END" | tr -d '\r')
if [[ "$database_exists" == "1" ]]; then
  echo "Bazele de date există deja. Inițializarea demonstrativă este omisă."
  exit 0
fi

run_sql() {
  local database="$1"
  local file="$2"
  echo "Rulez ${file}"
  "$sqlcmd_bin" -S db -d "$database" -U sa -P "$MSSQL_SA_PASSWORD" -C -I -b -i "/workspace/${file}"
}

operational_scripts=(
  database/01_create_database_schemas_tables.sql
  database/02_seed_data.sql
  database/04_currency_conversion_eur.sql
  database/05_ecb_daily_exchange_rates.sql
  database/06_api_identity.sql
  database/07_simulated_market_quotes.sql
  database/08_portfolio_daily_history.sql
  database/09_cash_withdrawal.sql
  database/10_customer_notifications.sql
  database/11_currency_exchange.sql
  database/12_broker_order_rejection.sql
  database/13_broker_notifications.sql
  database/14_access_audit.sql
  database/15_account_administration_audit.sql
  database/16_watchlist_price_alerts.sql
  database/procedures/usp_ExecuteOrder.sql
  database/17_advanced_orders.sql
  database/18_advanced_order_creation.sql
  database/19_stop_order_activation.sql
  database/20_order_history_quantities.sql
  database/21_order_expiration.sql
  database/22_security_activity_audit.sql
  database/23_session_revocation.sql
  database/procedures/usp_CancelOrder.sql
  database/procedures/usp_DepositCash.sql
  database/triggers/trg_Order_StatusHistory.sql
  database/triggers/trg_Audit_TradingWorkflow.sql
  database/views/vw_CustomerCash.sql
  database/views/vw_OrderDetails.sql
  database/views/vw_Portfolio.sql
  database/indexes/01_order_indexes.sql
)

run_sql master "${operational_scripts[0]}"
for file in "${operational_scripts[@]:1}"; do
  run_sql BrokerageDB "$file"
done

etl_scripts=(
  etl/01_create_staging.sql
  etl/02_initial_load.sql
  etl/03_create_etl_control.sql
  etl/08_currency_reporting_eur.sql
  etl/09_stop_order_history_upgrade.sql
  etl/10_order_expiration_upgrade.sql
  etl/07_refresh_staging_from_oltp.sql
  etl/11_refresh_audit_staging.sql
)

for file in "${etl_scripts[@]}"; do
  run_sql BrokerageDB "$file"
done

warehouse_scripts=(
  warehouse/01_create_warehouse.sql
  warehouse/02_create_dimensions.sql
  warehouse/03_create_facts.sql
  warehouse/04_load_dimensions.sql
  warehouse/05_load_fact_trade.sql
  warehouse/06_create_analytics_indexes.sql
  warehouse/07_currency_reporting_eur.sql
  warehouse/08_create_fact_cash_transaction.sql
  warehouse/09_load_fact_cash_transaction.sql
  warehouse/10_create_fact_portfolio_daily_snapshot.sql
  warehouse/11_load_fact_portfolio_daily_snapshot.sql
  warehouse/12_create_fact_order_lifecycle.sql
  warehouse/13_load_fact_order_lifecycle.sql
  warehouse/15_create_fact_kyc.sql
  warehouse/16_load_fact_kyc.sql
  warehouse/17_upgrade_fact_order_lifecycle_stop_history.sql
  warehouse/18_upgrade_fact_order_expiration.sql
  warehouse/19_operational_audit_analytics.sql
  warehouse/views/01_create_powerbi_views.sql
)

run_sql master "${warehouse_scripts[0]}"
for file in "${warehouse_scripts[@]:1}"; do
  run_sql BrokerageDW "$file"
done

echo "Inițializarea Docker a bazelor de date s-a finalizat cu succes."
