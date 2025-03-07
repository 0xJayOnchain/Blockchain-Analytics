WITH sol_fees AS (
    SELECT 
        block_time,
        TRY_CAST(fee AS DECIMAL) AS fee
    FROM solana.transactions
    WHERE 
        block_time >= CURRENT_TIMESTAMP - INTERVAL '90' DAY
),
periods AS (
    SELECT 
        'Last 24 Hours' AS time_period, 
        INTERVAL '24' HOUR AS interval_value,
        NULL AS lower_bound,
        1 AS order_rank
    UNION ALL
    SELECT 
        'Previous 24 Hours' AS time_period, 
        INTERVAL '48' HOUR AS interval_value,
        INTERVAL '24' HOUR AS lower_bound,
        2 AS order_rank
    UNION ALL
    SELECT 
        'Last 30 Days' AS time_period, 
        INTERVAL '30' DAY AS interval_value,
        NULL AS lower_bound,
        3 AS order_rank
    UNION ALL
    SELECT 
        'Last 60 Days' AS time_period, 
        INTERVAL '60' DAY AS interval_value,
        NULL AS lower_bound,
        4 AS order_rank
    UNION ALL
    SELECT 
        'Last 90 Days' AS time_period, 
        INTERVAL '90' DAY AS interval_value,
        NULL AS lower_bound,
        5 AS order_rank
),
sol_fees_by_period AS (
    SELECT 
        p.time_period,
        p.order_rank,
        ROUND(SUM(sf.fee) / 1e9, 2) AS total_fees
    FROM periods p
    CROSS JOIN sol_fees sf
    WHERE 
        sf.block_time >= CURRENT_TIMESTAMP - p.interval_value
        AND (p.lower_bound IS NULL OR sf.block_time < CURRENT_TIMESTAMP - p.lower_bound)
    GROUP BY 
        p.time_period,
        p.order_rank
)
SELECT 
    time_period AS "Time Period",
    total_fees AS "Total Fees (SOL)"
FROM sol_fees_by_period
ORDER BY order_rank;
