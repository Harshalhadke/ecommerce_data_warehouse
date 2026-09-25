WITH
    ranked AS (
        SELECT
            order_item_id::INTEGER AS order_item_id,
            order_id::INTEGER AS order_id,
            product_id::INTEGER AS product_id,
            quantity::INTEGER AS quantity,
            unit_price::NUMERIC(10, 2) AS unit_price,
            discount_pct::NUMERIC(5, 2) AS discount_pct,
            line_total::NUMERIC(12, 2) AS line_total,
            loaded_at::TIMESTAMP AS loaded_at,
            'ingestion/data_output/order_items.csv' AS source_file, -- noqa
            ROW_NUMBER() OVER (
                -- order_item_id restarts per order, so key on both
                PARTITION BY order_id, order_item_id
                ORDER BY loaded_at DESC
            ) AS row_number
        FROM {{ source('staging_ecommerce', 'stg_order_items') }}
    )

SELECT
    order_id || '-' || order_item_id AS order_item_key,
    order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price,
    discount_pct,
    line_total,
    loaded_at,
    source_file
FROM ranked
WHERE row_number = 1
