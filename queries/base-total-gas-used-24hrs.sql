WITH base_gas_by_period AS (
    SELECT 
        (SUM(gas_used) / 1e18) AS total_gas_eth,
        CASE 
            WHEN block_time >= CURRENT_TIMESTAMP - INTERVAL '24' HOUR THEN 'Last 24 Hours'
            WHEN block_time >= CURRENT_TIMESTAMP - INTERVAL '48' HOUR 
                 AND block_time < CURRENT_TIMESTAMP - INTERVAL '24' HOUR THEN 'Previous 24 Hours'
        END AS time_period
    FROM gas.fees
    WHERE 
        blockchain = 'base'
        AND block_time >= CURRENT_TIMESTAMP - INTERVAL '48' HOUR
    GROUP BY 
        CASE 
            WHEN block_time >= CURRENT_TIMESTAMP - INTERVAL '24' HOUR THEN 'Last 24 Hours'
            WHEN block_time >= CURRENT_TIMESTAMP - INTERVAL '48' HOUR 
                 AND block_time < CURRENT_TIMESTAMP - INTERVAL '24' HOUR THEN 'Previous 24 Hours'
        END
)
SELECT 
    time_period AS "Time Period",
    total_gas_eth AS "Total Gas Used (ETH)"
FROM base_gas_by_period
WHERE time_period IS NOT NULL
ORDER BY 
    CASE 
        WHEN time_period = 'Last 24 Hours' THEN 1 
        WHEN time_period = 'Previous 24 Hours' THEN 2 
    END;
