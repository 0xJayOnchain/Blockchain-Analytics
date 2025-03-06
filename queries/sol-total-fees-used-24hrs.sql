WITH sol_fees_by_period AS (
    SELECT 
        ROUND(SUM(TRY_CAST(fee AS DECIMAL)) / 1e9, 2) AS total_fees,
        CASE 
            WHEN block_time >= current_timestamp - interval '24' hour THEN 'Last 24 Hours'
            WHEN block_time >= current_timestamp - interval '48' hour 
                 AND block_time < current_timestamp - interval '24' hour THEN 'Previous 24 Hours'
        END AS time_period
    FROM solana.transactions
    WHERE block_time >= current_timestamp - interval '48' hour
    GROUP BY 
        CASE 
            WHEN block_time >= current_timestamp - interval '24' hour THEN 'Last 24 Hours'
            WHEN block_time >= current_timestamp - interval '48' hour 
                 AND block_time < current_timestamp - interval '24' hour THEN 'Previous 24 Hours'
        END
)
SELECT time_period AS "Time Period", total_fees AS "Total Fees (SOL)"
FROM sol_fees_by_period
WHERE time_period IS NOT NULL
ORDER BY 
    CASE 
        WHEN time_period = 'Last 24 Hours' THEN 1 
        WHEN time_period = 'Previous 24 Hours' THEN 2 
    END;
