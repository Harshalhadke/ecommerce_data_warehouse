WITH
    ranked AS (
        SELECT
            order_id::INTEGER AS order_id,
            customer_id::INTEGER AS customer_id,
            store_id::INTEGER AS store_id,
            order_date::TIMESTAMP AS order_at,
            ship_date::TIMESTAMP AS shipped_at,
            delivery_date::TIMESTAMP AS delivered_at,
            CASE UPPER(TRIM(order_status))
                WHEN 'PROCESSING' THEN 'PROCESSING'
                WHEN 'SHIPPED' THEN 'SHIPPED'
                WHEN 'DELIVERED' THEN 'DELIVERED'
                WHEN 'CANCELLED' THEN 'CANCELLED'
                WHEN 'RETURNED' THEN 'RETURNED'
                ELSE 'UNKNOWN'
            END AS order_status,
            NULLIF(TRIM(payment_method), '') AS payment_method,
            NULLIF(TRIM(shipping_method), '') AS shipping_method,
            discount_amount::NUMERIC(10, 2) AS discount_amount,
            shipping_cost::NUMERIC(10, 2) AS shipping_cost,
            tax_amount::NUMERIC(10, 2) AS tax_amount,
            total_amount::NUMERIC(12, 2) AS total_amount,
            UPPER(TRIM(currency_code))::VARCHAR(3) AS currency_code,
            loaded_at::TIMESTAMP AS loaded_at,
            'ingestion/data_output/orders.csv' AS source_file, -- noqa
            ROW_NUMBER() OVER (
                PARTITION BY order_id
                ORDER BY loaded_at DESC, source_file DESC NULLS LAST
            ) AS row_number
        FROM {{ source('staging_ecommerce', 'stg_orders') }}
    )

SELECT
    order_id,
    customer_id,
    store_id,
    order_at,
    shipped_at,
    delivered_at,
    order_status,
    payment_method,
    shipping_method,
    discount_amount,
    shipping_cost,
    tax_amount,
    total_amount,
    currency_code,
    loaded_at,
    source_file
FROM ranked
WHERE row_number = 1
