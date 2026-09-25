{% macro purge_stale_staging_rows(table_name, retention_days=7, loaded_at_column='loaded_at') %}

    {% set purge_sql %}
    delete from staging.{{ table_name }}
    where {{ loaded_at_column }} < (current_timestamp - interval '{{ retention_days }} days')
{% endset %}

    {% if execute %}
        {% do run_query(purge_sql) %}
        {{ log('Purged staging.' ~ table_name ~ ' rows older than ' ~ retention_days ~ ' days', info=true) }}
    {% endif %}

{% endmacro %}
