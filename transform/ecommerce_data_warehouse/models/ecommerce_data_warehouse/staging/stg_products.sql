WITH
    ranked AS (
        SELECT
            product_id::INTEGER AS product_id,
            UPPER(TRIM(sku)) AS sku,
            TRIM(product_name) AS product_name,
            NULLIF(TRIM(description), '') AS description,
            NULLIF(TRIM(brand), '') AS brand,
            TRIM(department) AS department,
            TRIM(category) AS category,
            NULLIF(TRIM(subcategory), '') AS subcategory,
            unit_price::NUMERIC(10, 2) AS unit_price,
            unit_cost::NUMERIC(10, 2) AS unit_cost,
            weight_kg::NUMERIC(8, 3) AS weight_kg,
            supplier_id::INTEGER AS supplier_id,
            NULLIF(TRIM(supplier_name), '') AS supplier_name,
            COALESCE(is_active, TRUE) AS is_active,
            launch_date::DATE AS launch_date,
            loaded_at::TIMESTAMP AS loaded_at,
            'ingestion/data_output/products.csv' AS source_file, -- noqa
            ROW_NUMBER() OVER (
                PARTITION BY product_id
                ORDER BY loaded_at DESC
            ) AS row_number
        FROM {{ source('staging_ecommerce', 'stg_products') }}
    )

SELECT
    product_id,
    sku,
    product_name,
    description,
    brand,
    department,
    category,
    subcategory,
    unit_price,
    unit_cost,
    weight_kg,
    supplier_id,
    supplier_name,
    is_active,
    launch_date,
    loaded_at,
    source_file
FROM ranked
WHERE row_number = 1
