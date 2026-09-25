WITH
    ranked AS (
        SELECT
            event_id::BIGINT AS event_id,
            customer_id::INTEGER AS customer_id,
            LOWER(TRIM(event_type)) AS event_type,
            event_timestamp::TIMESTAMP AS event_at,
            NULLIF(TRIM(session_id), '') AS session_id,
            NULLIF(TRIM(page_url), '') AS page_url,
            LOWER(TRIM(device_type)) AS device_type,
            NULLIF(TRIM(browser), '') AS browser,
            NULLIF(TRIM(referrer_source), '') AS referrer_source,
            event_properties::JSONB AS event_properties,
            loaded_at::TIMESTAMP AS loaded_at,
            'ingestion/data_output/customer_events.csv' AS source_file, -- noqa
            ROW_NUMBER() OVER (
                PARTITION BY event_id
                ORDER BY loaded_at DESC
            ) AS row_number
        FROM {{ source('staging_ecommerce', 'stg_customer_events') }}
    )

SELECT
    event_id,
    customer_id,
    event_type,
    event_at,
    session_id,
    page_url,
    device_type,
    browser,
    referrer_source,
    event_properties,
    loaded_at,
    source_file
FROM ranked
WHERE row_number = 1
