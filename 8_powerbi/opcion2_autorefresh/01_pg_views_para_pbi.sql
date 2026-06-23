-- ============================================================
-- CECOMSAP · Vistas optimizadas para Power BI Auto-Refresh
-- Schema: marts · ejecutar en PostgreSQL dw_cecomsap
-- ============================================================

-- ─── Vista maestra para importación en Power BI ───────────────
-- Joins pre-calculados → Power BI no necesita hacerlos en runtime
CREATE OR REPLACE VIEW marts.vw_cartera_pbi AS
SELECT
    -- Identificación
    f.cod,
    c.titular,
    c.documento_identidad,

    -- Dimensión fecha
    f.fecha_desembolso,
    df.anio                     AS anio_desembolso,
    df.nombre_mes               AS mes_desembolso,
    df.trimestre                AS trimestre_desembolso,
    f.fecha_ultimo_pago,

    -- Dimensión producto
    p.tipo_credito,
    p.descripcion_tipo,
    p.producto,
    p.familia_producto,
    f.frecuencia_pago,
    f.plazo,
    f.tasa_interes,

    -- Dimensión cliente
    c.genero,
    c.rango_etario,
    c.edad,
    c.tipo_vivienda,
    c.region,
    c.ubigeo,
    c.ley_laboral,
    c.es_rural,

    -- Dimensión gestor
    g.gestor,
    g.gestor_origen,
    g.analista,

    -- Dimensión calificación
    k.calificacion,
    k.descripcion               AS descripcion_calificacion,
    k.nivel_riesgo,
    k.orden_riesgo,

    -- Métricas financieras
    f.monto_credito,
    f.saldo_credito,
    f.capital_atraso,
    f.interes_devengado,
    f.mora,
    f.total_deuda,
    f.capital_vencido,
    f.interes_vencido,
    f.provision_cartera,
    f.cuota_referencia,
    f.saldo_ahorro,

    -- Indicadores de mora
    f.dias_atraso,
    f.cuotas_atraso,
    f.cuotas_pagadas,
    f.bucket_atraso,

    -- KPIs calculados
    f.tasa_morosidad_pct,
    f.pct_saldo_vs_desembolso,

    -- Flags booleanos (fácil de usar en Power BI)
    CASE WHEN f.dias_atraso > 0   THEN 1 ELSE 0 END  AS es_moroso,
    CASE WHEN f.dias_atraso > 90  THEN 1 ELSE 0 END  AS mora_critica,
    CASE WHEN k.calificacion = 'NOR' THEN 1 ELSE 0 END AS es_normal,

    -- Fecha de corte y metadata
    f.fecha_corte,
    f.cdc_timestamp             AS ultima_actualizacion

FROM marts.fact_cartera       f
LEFT JOIN marts.dim_cliente   c ON c.customer_id = f.customer_id
LEFT JOIN marts.dim_producto  p ON p.product_id  = f.product_id
LEFT JOIN marts.dim_gestor    g ON g.gestor_id   = f.gestor_id
LEFT JOIN marts.dim_calificacion k ON k.calif_id = f.calif_id
LEFT JOIN marts.dim_fecha     df ON df.date_id   = f.date_id_desembolso;

COMMENT ON VIEW marts.vw_cartera_pbi IS
  'Vista desnormalizada para importación directa en Power BI. Actualizada por dbt.';


-- ─── Vista de KPIs resumen (tarjetas Power BI) ───────────────
CREATE OR REPLACE VIEW marts.vw_kpis_resumen AS
SELECT
    COUNT(*)                                          AS total_creditos,
    ROUND(SUM(saldo_credito),      2)                 AS saldo_vigente_total,
    ROUND(SUM(monto_credito),      2)                 AS cartera_desembolsada,
    ROUND(SUM(capital_atraso),     2)                 AS capital_en_mora,
    ROUND(SUM(mora),               2)                 AS mora_total,
    ROUND(SUM(provision_cartera),  2)                 AS provision_total,
    ROUND(AVG(tasa_interes),       4)                 AS tasa_promedio,
    ROUND(AVG(dias_atraso),        1)                 AS dias_atraso_promedio,
    COUNT(*) FILTER (WHERE dias_atraso > 0)           AS creditos_morosos,
    COUNT(*) FILTER (WHERE dias_atraso > 90)          AS mora_critica,
    ROUND(
        SUM(capital_atraso) / NULLIF(SUM(saldo_credito),0) * 100, 2
    )                                                 AS indice_morosidad_pct,
    ROUND(
        SUM(provision_cartera) / NULLIF(SUM(capital_atraso),0) * 100, 2
    )                                                 AS cobertura_provision_pct,
    MAX(cdc_timestamp)                                AS ultima_actualizacion,
    CURRENT_TIMESTAMP                                 AS timestamp_consulta
FROM marts.fact_cartera;


-- ─── Vista por gestor (tabla de rendimiento) ─────────────────
CREATE OR REPLACE VIEW marts.vw_rendimiento_gestor AS
SELECT
    g.gestor,
    COUNT(f.cod)                                      AS creditos,
    ROUND(SUM(f.saldo_credito),    2)                 AS saldo_total,
    ROUND(SUM(f.capital_atraso),   2)                 AS capital_mora,
    COUNT(f.cod) FILTER (WHERE f.dias_atraso > 0)     AS creditos_morosos,
    COUNT(f.cod) FILTER (WHERE f.dias_atraso > 90)    AS mora_critica,
    ROUND(AVG(f.dias_atraso),      1)                 AS dias_atraso_prom,
    ROUND(
        SUM(f.capital_atraso) / NULLIF(SUM(f.saldo_credito),0) * 100, 2
    )                                                 AS indice_mora_pct,
    ROUND(SUM(f.provision_cartera),2)                 AS provision
FROM marts.fact_cartera f
JOIN marts.dim_gestor   g ON g.gestor_id = f.gestor_id
GROUP BY g.gestor
ORDER BY SUM(f.capital_atraso) DESC;


-- ─── Tabla de log de refrescos (para monitor) ────────────────
CREATE TABLE IF NOT EXISTS marts.refresh_log (
    id              SERIAL PRIMARY KEY,
    fuente          VARCHAR(30),   -- 'kafka_consumer' | 'dbt_run' | 'pbi_refresh'
    registros       INT,
    duracion_seg    NUMERIC(8,2),
    estado          VARCHAR(10),   -- 'OK' | 'ERROR'
    detalle         TEXT,
    ts              TIMESTAMP DEFAULT NOW()
);

-- Índice para consultas rápidas de estado
CREATE INDEX IF NOT EXISTS idx_refresh_log_ts ON marts.refresh_log(ts DESC);

-- Grant lectura a Power BI (usuario de solo lectura)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'pbi_reader') THEN
        CREATE ROLE pbi_reader LOGIN PASSWORD 'pbi_readonly_2026';
    END IF;
END
$$;

GRANT USAGE  ON SCHEMA marts     TO pbi_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA marts TO pbi_reader;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA marts TO pbi_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA marts
    GRANT SELECT ON TABLES TO pbi_reader;
