# S1 P3 — Validación OLTP

## Consulta de verificación

```sql
SELECT
    COUNT(cod)                    AS total_creditos,
    ROUND(SUM(saldo_credito), 2)  AS saldo_total,
    ROUND(SUM(capital_atraso), 2) AS mora_total,
    ROUND(SUM(provision), 2)      AS provision_total
FROM oltp_cecomsap.cartera;
```

## Resultado esperado

| Campo | Valor |
|-------|-------|
| total_creditos | 704 |
| saldo_total | 12,586,209.81 |
| mora_total | 1,727,882.73 |
| provision_total | 2,068,604.08 |
