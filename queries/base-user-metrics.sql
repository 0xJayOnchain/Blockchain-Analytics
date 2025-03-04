-- https://dune.com/queries/4770108
/* Identify first transactions for each address */
WITH first_transactions AS (
  SELECT
    "from" AS wallet_address,
    MIN(block_time) AS first_tx_date
  FROM base.transactions
  GROUP BY 1
), new_users AS (
  SELECT
    DATE_TRUNC('day', first_txns) AS time_,
    COUNT(*) AS new_users
  FROM (
    SELECT DISTINCT
      "from",
      MIN(block_time) AS first_txns
    FROM base.transactions
    GROUP BY 1
  ) AS first_txns
  GROUP BY 1
), tx_by_user_age AS (
  SELECT
    DATE_TRUNC('day', t.block_time) AS time_,
    t."from" AS wallet_address,
    CASE
      WHEN ft.first_tx_date >= DATE_TRUNC('day', t.block_time) - INTERVAL '7' DAY
      THEN 'New User'
      ELSE 'Old User'
    END AS user_type,
    COUNT(*) AS tx_count
  FROM base.transactions AS t
  JOIN first_transactions AS ft
    ON t."from" = ft.wallet_address
  WHERE
    t.block_time BETWEEN CURRENT_DATE - INTERVAL '365' day AND CURRENT_DATE - INTERVAL '1' day
  GROUP BY 1, 2, 3
), daily_txn_count AS (
  SELECT
    time_ AS time_,
    SUM(CASE WHEN user_type = 'New User' THEN tx_count ELSE 0 END) AS new_user_txns,
    SUM(CASE WHEN user_type = 'Old User' THEN tx_count ELSE 0 END) AS old_user_txns,
    SUM(tx_count) AS total_txns,
    COUNT(DISTINCT CASE WHEN tx_count > 0 THEN wallet_address END) AS active_addresses,
    SUM(t.gas_used) AS daily_gas_used,
    SUM(t.gas_used) / 1e9 AS daily_gas_used_gwei,
    SUM(t.gas_used) / 1e18 AS daily_gas_used_eth
  FROM tx_by_user_age AS tx
  JOIN base.transactions AS t ON tx.time_ = DATE_TRUNC('day', t.block_time) AND tx.wallet_address = t."from"
  GROUP BY 1
), monthly_data AS (
  SELECT
    DATE_TRUNC('month', time_) AS month_,
    SUM(new_users) AS monthly_new_users
  FROM new_users
  WHERE
    time_ BETWEEN CURRENT_DATE - INTERVAL '365' day AND CURRENT_DATE - INTERVAL '1' day
  GROUP BY 1
)
SELECT
  n.time_ AS "Date",
  n.new_users AS "New Addresses",
  ROUND(
    AVG(n.new_users) OVER (ORDER BY n.time_ ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)
  ) AS "7d New Address Avg",
  d.new_user_txns AS "New User Transactions",
  d.old_user_txns AS "Old User Transactions",
  d.total_txns AS "Daily Transactions",
  d.active_addresses AS "Daily Active Addresses",
  d.daily_gas_used AS "Daily Gas Used",
  d.daily_gas_used_gwei AS "Daily Gas Used (Gwei)",
  d.daily_gas_used_eth AS "Daily Gas Used (ETH)",
  CASE
    WHEN LAG(d.active_addresses, 7) OVER (ORDER BY n.time_) > 0
    THEN ROUND(
      (d.active_addresses * 100.0) / LAG(d.active_addresses, 7) OVER (ORDER BY n.time_),
      2
    )
    ELSE NULL
  END AS "7d Retention Rate",
  ROUND(
    (n.new_users - LAG(n.new_users, 1) OVER (ORDER BY n.time_)) * 100.0 / 
    NULLIF(LAG(n.new_users, 1) OVER (ORDER BY n.time_), 0),
    2
  ) AS "Daily Growth Rate"
FROM new_users AS n
JOIN daily_txn_count AS d
  ON n.time_ = d.time_
WHERE
  n.time_ BETWEEN CURRENT_DATE - INTERVAL '365' day AND CURRENT_DATE - INTERVAL '1' day
ORDER BY
  n.time_ DESC;
