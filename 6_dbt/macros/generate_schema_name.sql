{# Usa el +schema del config tal cual (sin prefijar con target.schema).
   Esto hace que models/marts/* vayan al schema "marts" en vez de "staging_marts". #}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema | trim }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
