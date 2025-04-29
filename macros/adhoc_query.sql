{% macro adhoc_query(sql) %}
    {% set results = run_query(sql) %}
    {% if execute %}
        {{ results }}
    {% endif %}
{% endmacro %}
