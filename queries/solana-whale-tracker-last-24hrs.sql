SELECT
  tx_id AS "Transaction Hash",
  from_owner AS "From",
  to_owner AS "To",
  symbol AS "Token",
  amount_usd AS "Transaction Amount (USD)",
  block_time AS "Date/Time"
FROM tokens_solana.transfers
WHERE
  DATE_TRUNC('day', block_time) >= CURRENT_DATE - INTERVAL '1' DAY
  AND amount_usd > 1000000
ORDER BY block_time DESC
LIMIT 1000
