-- ============================================================
-- VALIDACIÓN 1: OLTP (MySQL) vs RAW (PostgreSQL)
-- Verifica que la ingesta conserve registros y totales
-- ============================================================

-- 1.1 Conteo de registros
-- Ejecutar en MySQL:
-- SELECT COUNT(*) AS total_oltp FROM oltp_cecomsap.cartera;

-- Ejecutar en PostgreSQL:
SELECT
    COUNT(*)                          AS total_raw,
    COUNT(DISTINCT cod)               AS creditos_unicos,
    MIN(_cdc_ts)                      AS primer_registro,
    MAX(_cdc_ts)                      AS ultimo_registro
FROM raw.cartera;

-- 1.2 Totales financieros (comparar con MySQL)
SELECT
    ROUND(SUM(monto_credito),  2)     AS sum_monto_credito,
    ROUND(SUM(saldo_credito),  2)     AS sum_saldo_credito,
    ROUND(SUM(capital_atraso), 2)     AS sum_capital_atraso,
    ROUND(SUM(mora),           2)     AS sum_mora,
    ROUND(SUM(provision),      2)     AS sum_provision,
    ROUND(AVG(dias_atrs),      2)     AS avg_dias_atraso
FROM raw.cartera
WHERE cod IS NOT NULL;

-- 1.3 Distribución por calificación
SELECT
    calif,
    COUNT(*)                          AS cantidad,
    ROUND(SUM(saldo_credito),  2)     AS saldo_total,
    ROUND(AVG(dias_atrs),      1)     AS dias_atraso_promedio
FROM raw.cartera
GROUP BY calif
ORDER BY COUNT(*) DESC;

-- 1.4 Registros nulos críticos
SELECT
    COUNT(*) FILTER (WHERE titular IS NULL)       AS nulos_titular,
    COUNT(*) FILTER (WHERE tcr IS NULL)           AS nulos_tipo_credito,
    COUNT(*) FILTER (WHERE monto_credito IS NULL) AS nulos_monto,
    COUNT(*) FILTER (WHERE saldo_credito IS NULL) AS nulos_saldo,
    COUNT(*) FILTER (WHERE calif IS NULL)         AS nulos_calificacion,
    COUNT(*) FILTER (WHERE gestor IS NULL)        AS nulos_gestor
FROM raw.cartera;

-- 1.5 Duplicados en clave primaria
SELECT cod, COUNT(*) AS veces
FROM raw.cartera
GROUP BY cod
HAVING COUNT(*) > 1;
-- Resultado esperado: 0 filas
