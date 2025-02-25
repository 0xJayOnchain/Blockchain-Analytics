-- https://dune.com/queries/4770108
-- Identify first transactions for each address
WITH new_users AS (
    SELECT
        DATE_TRUNC('day', first_txns) AS time_,
        COUNT(*) AS new_users
    FROM (
        SELECT DISTINCT
            "from",
            MIN(block_time) AS first_txns
        FROM
            base.transactions AS a
        GROUP BY 1
    ) AS first_txns
    GROUP BY 1
),

-- Add daily transaction count for comparison
daily_txn_count AS (
    SELECT
        DATE_TRUNC('day', block_time) AS time_,
        COUNT(*) AS total_txns,
        COUNT(DISTINCT "from") AS active_addresses
    FROM
        base.transactions
    WHERE
        block_time BETWEEN current_date - interval '365' day AND current_date - interval '1' day
    GROUP BY 1
),

-- Monthly aggregation for trend analysis
monthly_data AS (
    SELECT
        DATE_TRUNC('month', time_) AS month_,
        SUM(new_users) AS monthly_new_users
    FROM
        new_users
    WHERE
        time_ BETWEEN current_date - interval '365' day AND current_date - interval '1' day
    GROUP BY 1
)

-- Final result with metrics and growth calculations
SELECT 
    n.time_ AS "Date",
    n.new_users AS "New Addresses",
    ROUND(AVG(n.new_users) OVER(ORDER BY n.time_ ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)) AS "7d New Address Avg",
    d.total_txns AS "Daily Transactions",
    d.active_addresses AS "Daily Active Addresses",
    
    -- Calculate address retention: how many addresses from 7 days ago are still active today
    CASE 
        WHEN LAG(d.active_addresses, 7) OVER(ORDER BY n.time_) > 0 
        THEN ROUND((d.active_addresses * 100.0) / LAG(d.active_addresses, 7) OVER(ORDER BY n.time_), 2)
        ELSE NULL
    END AS "7d Retention Rate",
    
    -- Calculate day-over-day growth rate
    ROUND((n.new_users - LAG(n.new_users, 1) OVER(ORDER BY n.time_)) * 100.0 / 
        NULLIF(LAG(n.new_users, 1) OVER(ORDER BY n.time_), 0), 2) AS "Daily Growth Rate"
FROM 
    new_users n
JOIN 
    daily_txn_count d ON n.time_ = d.time_
WHERE 
    n.time_ BETWEEN current_date - interval '365' day AND current_date - interval '1' day
ORDER BY 
    n.time_ DESC
