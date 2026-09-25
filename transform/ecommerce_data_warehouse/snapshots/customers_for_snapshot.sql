{% snapshot snp_customers %}

{{
    config(
        target_schema='snapshots',
        unique_key='customer_id',
        strategy='check',
        check_cols=['customer_segment', 'loyalty_tier', 'geography_key'],
        snapshot_meta_column_names={
            'dbt_valid_from': 'valid_from',
            'dbt_valid_to': 'valid_to',
            'dbt_scd_id': 'customer_key',
            'dbt_updated_at': 'updated_at'
        },
        post_hook="{{ purge_old_snapshot_versions(this, retention_days=7) }}"
    )
}}

select
    stg.customer_id,
    stg.first_name,
    stg.last_name,
    stg.email,
    stg.phone,
    stg.customer_segment,
    stg.loyalty_tier,
    geo.geography_key,
    stg.acquisition_channel,
    stg.acquisition_date
from {{ ref('stg_customers') }} as stg
left join {{ source('raw_ecommerce', 'dim_geography') }} as geo
    on
        stg.postal_code = geo.postal_code
        and stg.city = geo.city
        and stg.country_code = geo.country_code

{% endsnapshot %}