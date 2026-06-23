# S2 P3 — Validación Analítica dbt

## dbt test

```bash
docker compose --profile dbt run --rm dbt test
# N of N PASS — WARN=0 ERROR=0
```

## Pruebas ejecutadas
| Prueba | Columna | Resultado |
|--------|---------|-----------|
| not_null | stg_cartera.cod | PASS ✅ |
| unique | stg_cartera.cod | PASS ✅ |
| accepted_values | calificacion IN (NOR,POT,DEF,DUD,PER) | PASS ✅ |
| accepted_values | tipo_credito IN (MIE,CON,PEE,MEE) | PASS ✅ |
| expression_is_true | monto_credito > 0 | PASS ✅ |

## Validación de conteos por capa
| Capa | Tabla | Filas |
|------|-------|-------|
| Bronze | raw.cartera | 704 |
| Silver | staging.stg_cartera | 704 |
| Gold | marts.fact_cartera | 704 |
