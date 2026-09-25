{{ config(materialized='table') }}

SELECT
    {{ dbt_utils.generate_surrogate_key(['history.customer_id', 'history.valid_from']) }} AS customer_key,
    history.customer_id,
    history.first_name,
    history.last_name,
    history.email,
    history.phone,
    history.customer_segment,
    history.loyalty_tier,
    history.geography_key,
    history.acquisition_channel,
    history.acquisition_date,
    history.valid_from AS effective_start_date,
    COALESCE(history.valid_to, '9999-12-31'::TIMESTAMP) AS effective_end_date,
    history.valid_to IS null AS is_current,
    ROW_NUMBER() OVER (
        PARTITION BY history.customer_id
        ORDER BY history.valid_from
    ) AS version -- noqa: RF04
FROM {{ ref('snp_customers') }} AS history
