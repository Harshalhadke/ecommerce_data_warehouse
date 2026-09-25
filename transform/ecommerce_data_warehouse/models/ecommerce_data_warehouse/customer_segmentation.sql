{{ config(materialized='table') }}
--This script groups customers based on Recency (latest purchase), Frequency (how often they buy),
--and Monetary value (total spend).
--It provides a clean executive summary showing how many customers are in each group, their average behavior,
--and the total revenue that segment represents.


WITH
    customer_metrics AS (
        SELECT
            fo.customer_key,
            dc.customer_id,
            dc.first_name || ' ' || dc.last_name AS customer_name,
            dc.customer_segment,
            dc.acquisition_channel,
            CURRENT_DATE - MAX(dd.full_date) AS days_since_last_purchase,
            COUNT(DISTINCT fo.order_id) AS total_orders,
            SUM(fo.total_amount) AS total_revenue,
            ROUND(AVG(fo.total_amount), 2) AS avg_order_value,
            MIN(dd.full_date) AS first_purchase_date,
            MAX(dd.full_date) AS last_purchase_date
        FROM {{ ref('fact_orders') }} AS fo
        INNER JOIN {{ ref('dim_customers') }} AS dc
            ON fo.customer_key = dc.customer_key AND dc.is_current = true
        INNER JOIN {{ source('raw_ecommerce', 'dim_date') }} AS dd
            ON fo.order_date_key = dd.date_key
        WHERE fo.order_status != 'CANCELLED'
        GROUP BY
            fo.customer_key, dc.customer_id, dc.first_name, dc.last_name,
            dc.customer_segment, dc.acquisition_channel
    ),

    rfm_scores AS (
        SELECT
            *,
            NTILE(5) OVER (ORDER BY days_since_last_purchase DESC) AS r_score,
            NTILE(5) OVER (ORDER BY total_orders ASC) AS f_score,
            NTILE(5) OVER (ORDER BY total_revenue ASC) AS m_score
        FROM customer_metrics
    ),

    segement_summary AS (
        SELECT
            *,
            r_score * 100 + f_score * 10 + m_score AS rfm_combined,
            CASE
                WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
                WHEN r_score >= 4 AND f_score >= 3 THEN 'Loyal Customers'
                WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
                WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Potential Loyalists'
                WHEN r_score >= 3 AND f_score <= 2 AND m_score <= 2 THEN 'Promising'
                WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 4 THEN 'At Risk'
                WHEN r_score <= 2 AND f_score >= 3 THEN 'About to Sleep'
                WHEN r_score <= 2 AND f_score <= 2 AND m_score >= 3 THEN 'Cant Lose Them'
                WHEN r_score <= 1 AND f_score <= 2 THEN 'Lost'
                ELSE 'Need Attention'
            END AS rfm_segment
        FROM rfm_scores
    )

SELECT
    rfm_segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(days_since_last_purchase)) AS avg_recency_days,
    ROUND(AVG(total_orders), 1) AS avg_frequency,
    ROUND(AVG(total_revenue), 2) AS avg_monetary,
    ROUND(SUM(total_revenue), 2) AS segment_total_revenue,
    ROUND(AVG(avg_order_value), 2) AS avg_aov
FROM segement_summary
GROUP BY rfm_segment
ORDER BY avg_monetary DESC
