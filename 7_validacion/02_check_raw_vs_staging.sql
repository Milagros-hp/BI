-- ============================================================
-- VALIDACIÓN 2: RAW vs STAGING
-- Verifica que dbt limpie sin perder información crítica
-- ============================================================

-- 2.1 Conteo comparado
SELECT
    (SELECT COUNT(*) FROM raw.cartera)     AS total_raw,
    (SELECT COUNT(*) FROM staging.stg_cartera) AS total_staging,
    (SELECT COUNT(*) FROM raw.cartera) -
    (SELECT COUNT(*) FROM staging.stg_cartera) AS diferencia;
-- Diferencia esperada: filas con monto_credito = 0 o saldo nulo

-- 2.2 Totales financieros raw vs staging
SELECT 'RAW'     AS capa, ROUND(SUM(saldo_credito),2) AS sum_saldo,
       ROUND(SUM(capital_atraso),2) AS sum_atraso, ROUND(SUM(mora),2) AS sum_mora
FROM raw.cartera
UNION ALL
SELECT 'STAGING', ROUND(SUM(saldo_credito),2), ROUND(SUM(capital_atraso),2), ROUND(SUM(mora),2)
FROM staging.stg_cartera;

-- 2.3 Verificar campos calculados correctos
SELECT
    bucket_atraso,
    COUNT(*)                               AS cantidad,
    MIN(dias_atraso)                       AS dias_min,
    MAX(dias_atraso)                       AS dias_max
FROM staging.stg_cartera
GROUP BY bucket_atraso
ORDER BY dias_min;

-- 2.4 Rango de edades calculadas
SELECT
    MIN(edad)        AS edad_minima,
    MAX(edad)        AS edad_maxima,
    AVG(edad)::INT   AS edad_promedio,
    COUNT(*) FILTER (WHERE edad IS NULL OR edad < 0) AS edades_invalidas
FROM staging.stg_cartera;

-- 2.5 Valores aceptables en campos categóricos
SELECT tipo_credito, COUNT(*) FROM staging.stg_cartera GROUP BY 1 ORDER BY 2 DESC;
SELECT calificacion, COUNT(*) FROM staging.stg_cartera GROUP BY 1 ORDER BY 2 DESC;
SELECT genero,       COUNT(*) FROM staging.stg_cartera GROUP BY 1 ORDER BY 2 DESC;

-- 2.6 Nulos en staging (deben ser menores que en raw)
SELECT
    COUNT(*) FILTER (WHERE gestor IS NULL)          AS nulos_gestor,
    COUNT(*) FILTER (WHERE calificacion IS NULL)    AS nulos_calificacion,
    COUNT(*) FILTER (WHERE saldo_credito = 0)       AS saldos_cero,
    COUNT(*) FILTER (WHERE monto_credito <= 0)      AS montos_invalidos
FROM staging.stg_cartera;
