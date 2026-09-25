{% macro purge_old_snapshot_versions(snapshot_relation, retention_days=180, valid_to_column='valid_to') %}

    {% set purge_sql %}
    delete from {{ snapshot_relation }}
    where {{ valid_to_column }} is not null
      and {{ valid_to_column }} < (current_date - interval '{{ retention_days }} days')
{% endset %}

    {% if execute %}
        {% do run_query(purge_sql) %}
        {{ log('Purged snapshot rows with ' ~ valid_to_column ~ ' older than ' ~ retention_days ~ ' days from ' ~ snapshot_relation, info=true) }}
    {% endif %}

{% endmacro %}
