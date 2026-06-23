# U3 — Trazabilidad

La trazabilidad se mantiene mediante el campo `_cdc_ts` en `cartera` y la separación de capas (`raw` → `staging` → `marts`).

Ver `5_postgres/01_create_schemas.sql`, `2_mysql/01_create_oltp_table.sql` y `6_dbt/models/staging/stg_cartera.sql`.
