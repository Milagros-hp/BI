# S3 P2 — KPIs y Consultas SQL

## KPI 1: Saldo Vigente Total
```sql
SELECT ROUND(SUM(saldo_credito), 2) AS saldo_vigente
FROM marts.fact_cartera;
-- S/ 12,586,209.81
```

## KPI 2: Capital en Mora
```sql
SELECT ROUND(SUM(capital_atraso), 2) AS capital_mora
FROM marts.fact_cartera;
-- S/ 1,727,882.73
```

## KPI 3: Índice de Morosidad %
```sql
SELECT ROUND(
    SUM(capital_atraso) / NULLIF(SUM(saldo_credito),0) * 100, 2
) AS indice_morosidad_pct
FROM marts.fact_cartera;
-- 13.73%
```

## KPI 4: Provisión Total
```sql
SELECT ROUND(SUM(provision_cartera), 2) AS provision_total
FROM marts.fact_cartera;
-- S/ 2,068,604.08
```

## KPI 5: Cobertura de Provisión %
```sql
SELECT ROUND(
    SUM(provision_cartera) / NULLIF(SUM(capital_atraso),0) * 100, 2
) AS cobertura_provision_pct
FROM marts.fact_cartera;
-- 119.72%
```

## KPI 6: % Cartera en Riesgo
```sql
SELECT ROUND(
    SUM(CASE WHEN dc.calificacion IN ('PER','DUD','DEF','POT')
        THEN fc.saldo_credito ELSE 0 END) /
    NULLIF(SUM(fc.saldo_credito),0) * 100, 2
) AS cartera_en_riesgo_pct
FROM marts.fact_cartera fc
JOIN marts.dim_calificacion dc ON fc.calif_id = dc.calif_id;
-- 17.06%
```
