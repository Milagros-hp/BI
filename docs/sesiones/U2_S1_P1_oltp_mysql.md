# S1 P1 — Levantar OLTP MySQL

Origen transaccional: MySQL database `oltp_cecomsap` con la tabla `cartera`.

Archivo de creación: `2_mysql/01_create_oltp_table.sql` — contiene la definición de columnas, índices y el campo `_cdc_ts` para CDC.

Carga inicial: `1_data/load_to_mysql.py` lee `BD MARZO26.xlsx` y hace upserts en MySQL.
