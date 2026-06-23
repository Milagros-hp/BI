-- ============================================================
-- VALIDACIÓN 3: STAGING vs MARTS
-- Verifica integridad referencial y consistencia del DataMart
-- ============================================================

-- 3.1 Conteos de tablas del DataMart
SELECT 'dim_fecha'        AS tabla, COUNT(*) AS registros FROM marts.dim_fecha
UNION ALL
SELECT 'dim_producto',      COUNT(*) FROM marts.dim_producto
UNION ALL
SELECT 'dim_cliente',       COUNT(*) FROM marts.dim_cliente
UNION ALL
SELECT 'dim_gestor',        COUNT(*) FROM marts.dim_gestor
UNION ALL
SELECT 'dim_calificacion',  COUNT(*) FROM marts.dim_calificacion
UNION ALL
SELECT 'fact_cartera',      COUNT(*) FROM marts.fact_cartera;

-- 3.2 Integridad referencial fact → dims
SELECT 'FK product_id sin match' AS check_name,
       COUNT(*) AS registros_huerfanos
FROM marts.fact_cartera f
WHERE f.product_id = -1

UNION ALL
SELECT 'FK gestor_id sin match',
       COUNT(*)
FROM marts.fact_cartera f
WHERE f.gestor_id = -1

UNION ALL
SELECT 'FK calif_id sin match',
       COUNT(*)
FROM marts.fact_cartera f
WHERE f.calif_id = -1

UNION ALL
SELECT 'FK date_id_desembolso sin match',
       COUNT(*)
FROM marts.fact_cartera f
WHERE f.date_id_desembolso = -1;

-- 3.3 Totales staging vs marts (deben coincidir)
SELECT
    (SELECT ROUND(SUM(saldo_credito),2)  FROM staging.stg_cartera) AS saldo_staging,
    (SELECT ROUND(SUM(saldo_credito),2)  FROM marts.fact_cartera)   AS saldo_marts,
    (SELECT ROUND(SUM(monto_credito),2)  FROM staging.stg_cartera) AS monto_staging,
    (SELECT ROUND(SUM(monto_credito),2)  FROM marts.fact_cartera)   AS monto_marts,
    (SELECT ROUND(SUM(mora),2)           FROM staging.stg_cartera) AS mora_staging,
    (SELECT ROUND(SUM(mora),2)           FROM marts.fact_cartera)   AS mora_marts;

-- 3.4 Distribución por calificación en fact
SELECT
    dc.calificacion,
    dc.nivel_riesgo,
    COUNT(f.cod)                          AS cantidad_creditos,
    ROUND(SUM(f.saldo_credito),  2)       AS saldo_total,
    ROUND(SUM(f.provision_cartera), 2)    AS provision_total,
    ROUND(AVG(f.dias_atraso), 1)          AS dias_atraso_prom
FROM marts.fact_cartera   f
JOIN marts.dim_calificacion dc ON dc.calif_id = f.calif_id
GROUP BY dc.calificacion, dc.nivel_riesgo, dc.orden_riesgo
ORDER BY dc.orden_riesgo;

-- 3.5 Distribución por producto en fact
SELECT
    dp.tipo_credito,
    dp.familia_producto,
    COUNT(f.cod)                          AS cantidad,
    ROUND(SUM(f.monto_credito), 2)        AS monto_total,
    ROUND(AVG(f.tasa_interes),  4)        AS tasa_promedio
FROM marts.fact_cartera f
JOIN marts.dim_producto dp ON dp.product_id = f.product_id
GROUP BY dp.tipo_credito, dp.familia_producto
ORDER BY COUNT(f.cod) DESC;

-- 3.6 Claves únicas en fact
SELECT cod, COUNT(*) AS veces
FROM marts.fact_cartera
GROUP BY cod HAVING COUNT(*) > 1;
-- Esperado: 0 filas
