# S3 — Modelo dimensional

El modelo dimensional está definido en `6_dbt/models/marts/marts.yml`.

- Dimensiones: `dim_fecha`, `dim_producto`, `dim_cliente`, `dim_gestor`, `dim_calificacion`.
- Hecho: `fact_cartera` (grano: un crédito al corte 31/03/2026).

Ver detalles y tests en `6_dbt/models/marts/marts.yml`.
