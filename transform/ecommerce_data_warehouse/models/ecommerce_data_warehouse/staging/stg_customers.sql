WITH
    ranked AS (
        SELECT
            customer_id::INTEGER AS customer_id,
            TRIM(first_name) AS first_name,
            TRIM(last_name) AS last_name,
            LOWER(TRIM(email)) AS email,
            NULLIF(TRIM(phone), '') AS phone,
            NULLIF(TRIM(customer_segment), '') AS customer_segment,
            NULLIF(TRIM(loyalty_tier), '') AS loyalty_tier,
            NULLIF(TRIM(postal_code), '') AS postal_code,
            TRIM(city) AS city,
            TRIM(state_province) AS state_province,
            UPPER(TRIM(country_code))::CHAR(2) AS country_code,
            NULLIF(TRIM(acquisition_channel), '') AS acquisition_channel,
            acquisition_date::DATE AS acquisition_date,
            loaded_at::TIMESTAMP AS loaded_at,
            'ingestion/data_output/customers.csv' AS source_file, -- noqa
            ROW_NUMBER() OVER (
                PARTITION BY customer_id
                ORDER BY loaded_at DESC
            ) AS row_number
        FROM {{ source('staging_ecommerce', 'stg_customers') }}
    )

SELECT
    customer_id,
    first_name,
    last_name,
    email,
    phone,
    customer_segment,
    loyalty_tier,
    postal_code,
    city,
    state_province,
    country_code,
    acquisition_channel,
    acquisition_date,
    loaded_at,
    source_file
FROM ranked
WHERE row_number = 1
