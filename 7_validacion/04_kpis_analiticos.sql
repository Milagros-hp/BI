-- ============================================================
-- VALIDACIÓN 4: KPIs ANALÍTICOS DEL DATAMART
-- Consultas que responden al negocio — base para Power BI
-- ============================================================

-- ─── KPI 1: Resumen general de cartera ───────────────────────
SELECT
    COUNT(cod)                                    AS total_creditos,
    ROUND(SUM(monto_credito),       2)            AS cartera_total_desembolsada,
    ROUND(SUM(saldo_credito),       2)            AS saldo_vigente_total,
    ROUND(SUM(capital_atraso),      2)            AS cartera_en_mora,
    ROUND(SUM(mora),                2)            AS interes_mora_total,
    ROUND(SUM(provision_cartera),   2)            AS provision_total,
    ROUND(AVG(tasa_interes),        4)            AS tasa_promedio,
    ROUND(AVG(dias_atraso),         1)            AS dias_atraso_promedio,
    ROUND(
        SUM(capital_atraso) / NULLIF(SUM(saldo_credito),0) * 100, 2
    )                                             AS indice_morosidad_pct
FROM marts.fact_cartera;


-- ─── KPI 2: Cartera por calificación SBS ─────────────────────
SELECT
    dc.calificacion,
    dc.descripcion,
    dc.nivel_riesgo,
    COUNT(f.cod)                                  AS creditos,
    ROUND(SUM(f.saldo_credito),    2)             AS saldo,
    ROUND(SUM(f.capital_atraso),   2)             AS capital_mora,
    ROUND(SUM(f.provision_cartera),2)             AS provision,
    ROUND(SUM(f.saldo_credito) /
          NULLIF((SELECT SUM(saldo_credito) FROM marts.fact_cartera),0)
          * 100, 2)                               AS pct_del_total
FROM marts.fact_cartera f
JOIN marts.dim_calificacion dc ON dc.calif_id = f.calif_id
GROUP BY dc.calificacion, dc.descripcion, dc.nivel_riesgo, dc.orden_riesgo
ORDER BY dc.orden_riesgo;


-- ─── KPI 3: Cartera por tipo de crédito y producto ───────────
SELECT
    dp.tipo_credito,
    dp.descripcion_tipo,
    dp.familia_producto,
    COUNT(f.cod)                                  AS creditos,
    ROUND(SUM(f.monto_credito), 2)                AS monto_desembolsado,
    ROUND(SUM(f.saldo_credito), 2)                AS saldo_vigente,
    ROUND(AVG(f.tasa_interes),  4)                AS tasa_promedio,
    ROUND(AVG(f.plazo),         1)                AS plazo_promedio
FROM marts.fact_cartera f
JOIN marts.dim_producto dp ON dp.product_id = f.product_id
GROUP BY dp.tipo_credito, dp.descripcion_tipo, dp.familia_producto
ORDER BY SUM(f.saldo_credito) DESC;


-- ─── KPI 4: Cartera por gestor (ranking de mora) ─────────────
SELECT
    dg.gestor,
    COUNT(f.cod)                                  AS creditos_asignados,
    ROUND(SUM(f.saldo_credito),    2)             AS saldo_total,
    ROUND(SUM(f.capital_atraso),   2)             AS capital_mora,
    COUNT(f.cod) FILTER (WHERE f.dias_atraso > 0) AS creditos_morosos,
    ROUND(
        SUM(f.capital_atraso) / NULLIF(SUM(f.saldo_credito),0) * 100, 2
    )                                             AS indice_mora_pct,
    ROUND(AVG(f.dias_atraso), 1)                  AS dias_atraso_prom
FROM marts.fact_cartera f
JOIN marts.dim_gestor dg ON dg.gestor_id = f.gestor_id
GROUP BY dg.gestor
ORDER BY SUM(f.capital_atraso) DESC;


-- ─── KPI 5: Cartera por bucket de atraso ─────────────────────
SELECT
    bucket_atraso,
    COUNT(cod)                                    AS creditos,
    ROUND(SUM(saldo_credito),    2)               AS saldo,
    ROUND(SUM(capital_atraso),   2)               AS capital_mora,
    ROUND(AVG(dias_atraso),      1)               AS dias_prom
FROM marts.fact_cartera
GROUP BY bucket_atraso
ORDER BY MIN(dias_atraso);


-- ─── KPI 6: Cartera por año de desembolso ────────────────────
SELECT
    df.anio,
    COUNT(f.cod)                                  AS creditos,
    ROUND(SUM(f.monto_credito), 2)                AS monto_desembolsado,
    ROUND(SUM(f.saldo_credito), 2)                AS saldo_vigente,
    ROUND(AVG(f.tasa_interes),  4)                AS tasa_promedio
FROM marts.fact_cartera f
JOIN marts.dim_fecha df ON df.date_id = f.date_id_desembolso
GROUP BY df.anio
ORDER BY df.anio;


-- ─── KPI 7: Perfil demográfico de la cartera ─────────────────
SELECT
    dc.genero,
    dc.rango_etario,
    COUNT(f.cod)                                  AS creditos,
    ROUND(SUM(f.monto_credito), 2)                AS monto_total,
    ROUND(AVG(f.monto_credito), 2)                AS monto_promedio,
    ROUND(AVG(f.dias_atraso),   1)                AS dias_atraso_prom
FROM marts.fact_cartera f
JOIN marts.dim_cliente dc ON dc.customer_id = f.customer_id
GROUP BY dc.genero, dc.rango_etario
ORDER BY dc.genero, COUNT(f.cod) DESC;


-- ─── KPI 8: Comparación OLTP vs DataMart (para entregable) ──
SELECT
    'OLTP raw.cartera'  AS fuente,
    COUNT(*)            AS total_registros,
    ROUND(SUM(saldo_credito),  2) AS saldo_total,
    ROUND(SUM(capital_atraso), 2) AS mora_total,
    ROUND(SUM(provision),      2) AS provision_total
FROM raw.cartera

UNION ALL

SELECT
    'DataMart fact_cartera',
    COUNT(*),
    ROUND(SUM(saldo_credito),    2),
    ROUND(SUM(capital_atraso),   2),
    ROUND(SUM(provision_cartera),2)
FROM marts.fact_cartera;
-- Esperado: totales iguales entre ambas fuentes
