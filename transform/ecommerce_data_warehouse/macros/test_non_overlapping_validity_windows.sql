{% test non_overlapping_validity_windows(model, business_key) %}

-- fails if a record's valid_to extends past the next version's valid_from
with windows as (
    select
        {{ business_key }} as business_key,
        valid_from,
        valid_to,
        lead(valid_from) over (
            partition by {{ business_key }}
            order by valid_from
        ) as next_valid_from
    from {{ model }}
)

select *
from windows
where valid_to is not null
    and valid_to > next_valid_from

{% endtest %}
