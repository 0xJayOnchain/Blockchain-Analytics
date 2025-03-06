SELECT
  COUNT(DISTINCT active_user) AS total_active_users
FROM (
  SELECT DISTINCT
    "from" AS active_user
  FROM transfers_base.eth
  WHERE
    tx_block_time >= CURRENT_TIMESTAMP - INTERVAL '24' hour AND value > 1
  UNION
  SELECT DISTINCT
    "to" AS active_user
  FROM transfers_base.eth
  WHERE
    tx_block_time >= CURRENT_TIMESTAMP - INTERVAL '24' hour AND value > 1
) AS subquery
