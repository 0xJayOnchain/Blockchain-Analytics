WITH wallet_transactions AS (
  SELECT
    tx_hash AS transaction_hash,
    tx_from AS wallet_address,
    tx_to AS destination_address,
    symbol AS token,
    amount_usd AS transaction_amount_usd,
    block_time AS datetime
  FROM tokens_base.transfers
  WHERE
    blockchain = 'base' -- AND NOT symbol IN ('ETH', 'WETH', 'USDC', 'cbETH')
), high_value_wallets AS (
  SELECT
    transaction_hash,
    wallet_address,
    token,
    destination_address,
    transaction_amount_usd,
    datetime
  FROM wallet_transactions
  WHERE
    DATE_TRUNC('day', datetime) >= CURRENT_DATE - INTERVAL '1' DAY
), wallet_balances AS (
  SELECT
    wallet_address,
    token,
    SUM(CASE WHEN datetime < CURRENT_DATE THEN transaction_amount_usd ELSE 0 END) AS before_balance,
    SUM(transaction_amount_usd) AS after_balance_with_tx
  FROM wallet_transactions
  GROUP BY
    wallet_address,
    token
)
SELECT
  hw.transaction_hash,
  hw.wallet_address,
  hw.token,
  hw.destination_address,
  hw.transaction_amount_usd,
  hw.datetime,
  wb.before_balance,
  (
    wb.after_balance_with_tx - hw.transaction_amount_usd
  ) AS after_balance
FROM high_value_wallets AS hw
JOIN wallet_balances AS wb
  ON hw.wallet_address = wb.wallet_address AND hw.token = wb.token
WHERE
  hw.transaction_amount_usd > 1000000
ORDER BY
  hw.transaction_amount_usd DESC
