WITH
    ranked AS (
        SELECT
            inventory_id::INTEGER AS inventory_id,
            product_id::INTEGER AS product_id,
            store_id::INTEGER AS store_id,
            UPPER(TRIM(movement_type)) AS movement_type,
            quantity::INTEGER AS quantity,
            movement_date::TIMESTAMP AS movement_at,
            reference_id::INTEGER AS reference_id,
            loaded_at::TIMESTAMP AS loaded_at,
            'ingestion/data_output/inventory.csv' AS source_file, -- noqa
            ROW_NUMBER() OVER (
                PARTITION BY inventory_id
                ORDER BY loaded_at DESC
            ) AS row_number
        FROM {{ source('staging_ecommerce', 'stg_inventory') }}
    )

SELECT
    inventory_id,
    product_id,
    store_id,
    movement_type,
    quantity,
    movement_at,
    reference_id,
    loaded_at,
    source_file
FROM ranked
WHERE row_number = 1
