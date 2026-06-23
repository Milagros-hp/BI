# S1 P2 — Carga de Excel a MySQL

## Archivo fuente
`1_data/BD_MARZO26.xlsx` — 704 créditos al corte 31/03/2026.

## Ejecutar el loader

```bash
docker compose --profile load run --rm loader
# Output: 704 filas insertadas en oltp_cecomsap.cartera
```

## Verificar la carga

```sql
SELECT COUNT(*) FROM oltp_cecomsap.cartera;
-- 704
```
