SELECT
  COUNT(DISTINCT "from") AS new_addresses_last_24_hours
FROM base.transactions
WHERE
  block_time >= CURRENT_TIMESTAMP - INTERVAL '24' hour
  AND "from" IN (
    SELECT
      "from"
    FROM base.transactions
    GROUP BY
      "from"
    HAVING
      MIN(block_time) >= CURRENT_TIMESTAMP - INTERVAL '24' hour
  )
