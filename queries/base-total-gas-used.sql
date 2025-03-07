WITH base_gas AS (
  SELECT
    block_time,
    gas_used,
    SUM(gas_used / 1e18) AS gas_used_eth
  FROM gas.fees
  WHERE
    blockchain = 'base' AND block_time >= CURRENT_TIMESTAMP - INTERVAL '90' DAY
  GROUP BY
    block_time,
    gas_used
), periods AS (
  SELECT
    'Last 24 Hours' AS time_period,
    INTERVAL '24' HOUR AS interval_value,
    1 AS order_rank
  UNION ALL
  SELECT
    'Previous 24 Hours' AS time_period,
    INTERVAL '48' HOUR AS interval_value,
    2 AS order_rank
  UNION ALL
  SELECT
    'Last 30 Days' AS time_period,
    INTERVAL '30' DAY AS interval_value,
    3 AS order_rank
  UNION ALL
  SELECT
    'Last 60 Days' AS time_period,
    INTERVAL '60' DAY AS interval_value,
    4 AS order_rank
  UNION ALL
  SELECT
    'Last 90 Days' AS time_period,
    INTERVAL '90' DAY AS interval_value,
    5 AS order_rank
), base_gas_by_period AS (
  SELECT
    p.time_period,
    p.order_rank,
    SUM(bg.gas_used_eth) AS gas_used_eth
  FROM periods AS p
  CROSS JOIN base_gas AS bg
  WHERE
    bg.block_time >= CURRENT_TIMESTAMP - p.interval_value
  GROUP BY
    p.time_period,
    p.order_rank
)
SELECT
  time_period AS "Time Period",
  gas_used_eth AS "Total Gas Used (ETH)"
FROM base_gas_by_period
ORDER BY
  order_rank
