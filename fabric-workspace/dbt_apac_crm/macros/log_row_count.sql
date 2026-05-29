{% macro log_row_count(relation) %}
    {% set q %}select count(*) as n from {{ relation }}{% endset %}
    {% set r = run_query(q) %}
    {% if execute %}
        {% set n = r.columns[0].values()[0] %}
        {{ log("[" ~ relation.identifier ~ "] " ~ n ~ " rows", info=True) }}
    {% endif %}
{% endmacro %}
