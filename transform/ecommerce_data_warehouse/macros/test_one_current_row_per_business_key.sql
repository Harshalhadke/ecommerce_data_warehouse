{% test one_current_row_per_business_key(model, business_key, is_current_expression='valid_to is null') %}

select {{ business_key }}
from {{ model }}
where {{ is_current_expression }}
group by {{ business_key }}
having count(*) != 1

{% endtest %}
