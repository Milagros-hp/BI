# S3 P1 — Modelo Semántico en Metabase

## Conexión
Metabase conectado a PostgreSQL esquema `marts`.

## Tablas importadas
- `fact_cartera` — tabla de hechos central
- `dim_fecha` — dimensión tiempo
- `dim_producto` — dimensión tipo de crédito
- `dim_cliente` — dimensión socio titular
- `dim_gestor` — dimensión gestor de cobranza
- `dim_calificacion` — dimensión calificación SBS

## Relaciones
| Dimensión | Campo | fact_cartera | Tipo |
|-----------|-------|--------------|------|
| dim_fecha | date_id | date_id_desembolso | 1:* |
| dim_producto | product_id | product_id | 1:* |
| dim_cliente | customer_id | customer_id | 1:* |
| dim_gestor | gestor_id | gestor_id | 1:* |
| dim_calificacion | calif_id | calif_id | 1:* |
