{{
    config(
        materialized='incremental',
        unique_key='order_id',
        incremental_strategy='merge',
        on_schema_change='sync_all_columns'
    )
}}

WITH
    orders AS (
        SELECT
            stg.order_id,
            stg.customer_id,
            stg.store_id,
            stg.order_at,
            stg.shipped_at,
            stg.delivered_at,
            stg.order_status,
            stg.payment_method,
            stg.shipping_method,
            stg.discount_amount,
            stg.tax_amount,
            stg.shipping_cost,
            stg.total_amount,
            stg.currency_code,
            stg.loaded_at,
            ROW_NUMBER() OVER (
                PARTITION BY stg.customer_id ORDER BY stg.order_at
            ) = 1 AS is_first_order,
            (
                stg.order_at::DATE - LAG(stg.order_at::DATE) OVER (
                    PARTITION BY stg.customer_id ORDER BY stg.order_at
                )
            ) AS days_since_prior_order
        FROM {{ ref('stg_orders') }} AS stg
    ),

    item_counts AS (
        SELECT
            order_id,
            COUNT(*) AS item_count,
            SUM(line_total) AS gross_amount
        FROM {{ ref('stg_order_items') }}
        GROUP BY order_id
    ),

    filtered AS (
        SELECT *
        FROM orders
        {% if is_incremental() %}
            WHERE loaded_at >= (
                SELECT COALESCE(MAX(etl_loaded_at), '1900-01-01'::TIMESTAMP) - INTERVAL '3 days'
                FROM {{ this }}
            )
        {% endif %}
    )

SELECT
    filtered.order_id,
    dim_customers.customer_key,
    dim_stores.store_id AS store_key,
    TO_CHAR(filtered.order_at::DATE, 'YYYYMMDD')::INT AS order_date_key,
    CASE
        WHEN filtered.shipped_at IS NOT null
            THEN TO_CHAR(filtered.shipped_at::DATE, 'YYYYMMDD')::INT
    END AS ship_date_key,
    CASE
        WHEN filtered.delivered_at IS NOT null
            THEN TO_CHAR(filtered.delivered_at::DATE, 'YYYYMMDD')::INT
    END AS delivery_date_key,
    filtered.order_status,
    filtered.payment_method,
    filtered.shipping_method,
    COALESCE(item_counts.item_count, 0) AS item_count,
    COALESCE(item_counts.gross_amount, 0) AS gross_amount,
    filtered.discount_amount,
    COALESCE(item_counts.gross_amount, 0) - filtered.discount_amount AS net_amount,
    filtered.tax_amount,
    filtered.shipping_cost,
    filtered.total_amount,
    CASE
        WHEN filtered.shipped_at IS NOT null
            THEN (filtered.shipped_at::DATE - filtered.order_at::DATE)
    END AS days_to_ship,
    CASE
        WHEN filtered.delivered_at IS NOT null
            THEN (filtered.delivered_at::DATE - filtered.order_at::DATE)
    END AS days_to_deliver,
    filtered.days_since_prior_order,
    filtered.is_first_order,
    filtered.order_status = 'RETURNED' AS has_return,
    filtered.currency_code,
    CURRENT_TIMESTAMP AS etl_loaded_at
FROM filtered
INNER JOIN {{ ref('dim_customers') }} AS dim_customers
    ON
        filtered.customer_id = dim_customers.customer_id
        AND dim_customers.is_current = true
INNER JOIN {{ source('raw_ecommerce', 'dim_stores') }} AS dim_stores
    ON filtered.store_id = dim_stores.store_id
LEFT JOIN item_counts
    ON filtered.order_id = item_counts.order_id
