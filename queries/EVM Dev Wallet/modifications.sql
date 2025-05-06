WITH token_transfers AS (
    SELECT
        contract_address,
        "to" AS address,
        -CAST(value AS DOUBLE) AS delta
    FROM evms.erc20_transfers
    WHERE "to" = 0x0000000000000000000000000000000000000000
    UNION ALL
    SELECT
        contract_address,
        "from" AS address,
        CAST(value AS DOUBLE) AS delta
    FROM evms.erc20_transfers
    WHERE "from" = 0x0000000000000000000000000000000000000000
),

token_supply AS (
    SELECT
        contract_address,
        COALESCE(SUM(delta), 1e18) AS total_supply
    FROM token_transfers
    GROUP BY contract_address
),

token_prices AS (
    SELECT 
        t.address AS token_address,
        p.current_price AS current_price_usd,
        hp.highest_price AS all_time_high_price_usd
    FROM evms.creation_traces t
    LEFT JOIN (
        SELECT 
            contract_address,
            price AS current_price
        FROM prices.usd_latest
    ) p ON t.address = p.contract_address
    LEFT JOIN (
        SELECT 
            contract_address,
            MAX(price) AS highest_price
        FROM prices.minute
        WHERE timestamp >= CURRENT_TIMESTAMP - INTERVAL '{{Days_ago}}' DAY
        GROUP BY contract_address
    ) hp ON t.address = hp.contract_address
    WHERE t.blockchain = '{{blockchain}}'
),

token_metrics AS (
    SELECT
        ct."from" AS creator, 
        ct.address AS token_address, 
        COALESCE(tp.current_price_usd * ABS(ts.total_supply) / POWER(10, COALESCE(t2.decimals, 18)), 0) AS current_market_cap_usd, 
        CASE WHEN COALESCE(tp.all_time_high_price_usd * ABS(ts.total_supply) / POWER(10, COALESCE(t2.decimals, 18)), 0) >= 1000 THEN 1 ELSE 0 END AS is_successful, 
        ct.block_time AS creation_time,
        tp.current_price_usd,
        ts.total_supply,
        t2.decimals
    FROM evms.creation_traces ct 
    LEFT JOIN tokens.erc20 t2 ON ct.address = t2.contract_address AND ct.blockchain = t2.blockchain
    LEFT JOIN token_prices tp ON ct.address = tp.token_address
    LEFT JOIN token_supply ts ON ct.address = ts.contract_address
    WHERE ct.block_time >= CURRENT_TIMESTAMP - INTERVAL '{{Days_ago}}' DAY 
    AND ct.blockchain = '{{blockchain}}'
    AND tp.current_price_usd IS NOT NULL -- Only include tokens with price data
),

creator_metrics AS (
    SELECT
        creator, 
        COUNT(DISTINCT token_address) AS tokens_created, 
        AVG(current_market_cap_usd) AS avg_market_cap, 
        CAST(SUM(is_successful) AS DOUBLE) / CAST(COUNT(*) AS DOUBLE) * 100 AS success_rate, 
        MAX(creation_time) AS last_token_date
    FROM token_metrics 
    GROUP BY creator
)

SELECT
    cm.creator AS Deployer,
    cm.tokens_created AS Tokens_created,
    cm.avg_market_cap AS Average_market_cap,
    cm.success_rate,
    cm.last_token_date,
    AVG(tm.current_price_usd) AS avg_current_price_usd,
    AVG(tm.total_supply) AS avg_total_supply,
    AVG(tm.decimals) AS avg_decimals
FROM creator_metrics cm
LEFT JOIN token_metrics tm ON cm.creator = tm.creator
GROUP BY 
    cm.creator,
    cm.tokens_created,
    cm.avg_market_cap,
    cm.success_rate,
    cm.last_token_date
ORDER BY
    cm.tokens_created DESC
