-- models/marts/fact_cartera.sql
-- Tabla de Hechos: Cartera de Créditos CECOMSAP
-- Grano: un crédito por fila, al corte 31/03/2026

{{ config(
    materialized = 'incremental',
    unique_key   = 'cod',
    on_schema_change = 'sync_all_columns'
) }}

WITH stg AS (
    SELECT * FROM {{ ref('stg_cartera') }}

    {% if is_incremental() %}
        WHERE cdc_timestamp > (SELECT MAX(cdc_timestamp) FROM {{ this }})
    {% endif %}
),

dim_prod AS (
    SELECT product_id, tipo_credito, producto, frecuencia_pago
    FROM {{ ref('dim_producto') }}
),

dim_gest AS (
    SELECT gestor_id, gestor, gestor_origen, analista
    FROM {{ ref('dim_gestor') }}
),

dim_calif AS (
    SELECT calif_id, calificacion FROM {{ ref('dim_calificacion') }}
),

dim_fec AS (
    SELECT date_id, full_date FROM {{ ref('dim_fecha') }}
),

fact AS (
    SELECT
        -- ── Claves de dimensión ─────────────────────────────
        s.cod,
        s.cod                                        AS customer_id,

        COALESCE(dp.product_id,  -1)                 AS product_id,
        COALESCE(dg.gestor_id,   -1)                 AS gestor_id,
        COALESCE(dc.calif_id,    -1)                 AS calif_id,
        COALESCE(df.date_id,     -1)                 AS date_id_desembolso,
        COALESCE(df2.date_id,    -1)                 AS date_id_ultimo_pago,

        -- ── Atributos del crédito ───────────────────────────
        s.codigo_credito,
        s.tipo_credito,
        s.producto,
        s.frecuencia_pago,
        s.operacion_directa,
        s.plazo,
        s.tasa_interes,
        s.bucket_atraso,
        s.fecha_desembolso,
        s.fecha_ultimo_pago,
        s.fecha_cuota_pendiente,

        -- ── Métricas financieras ────────────────────────────
        s.monto_credito,
        s.saldo_credito,
        s.capital_atraso,
        s.interes_devengado,
        s.mora,
        s.total_deuda,
        s.capital_vencido,
        s.interes_vencido,
        s.provision_cartera,
        s.cuota_referencia,
        s.saldo_ahorro,

        -- ── Indicadores de mora ─────────────────────────────
        s.dias_atraso,
        s.cuotas_atraso,
        s.cuotas_pagadas,

        -- ── KPIs calculados ─────────────────────────────────
        CASE WHEN s.monto_credito > 0
             THEN ROUND((s.saldo_credito / s.monto_credito) * 100, 2)
             ELSE 0
        END                                          AS pct_saldo_vs_desembolso,

        CASE WHEN s.saldo_credito > 0
             THEN ROUND((s.capital_atraso / s.saldo_credito) * 100, 2)
             ELSE 0
        END                                          AS tasa_morosidad_pct,

        -- ── Fecha de corte ──────────────────────────────────
        CURRENT_DATE                                 AS fecha_corte,

        -- ── Metadata ────────────────────────────────────────
        s.cdc_operacion,
        s.cdc_timestamp

    FROM stg s
    LEFT JOIN dim_prod  dp ON dp.tipo_credito   = s.tipo_credito
                           AND dp.producto       = s.producto
                           AND dp.frecuencia_pago = s.frecuencia_pago
    LEFT JOIN dim_gest  dg ON dg.gestor          = s.gestor
                           AND dg.gestor_origen   = s.gestor_origen
                           AND dg.analista        = s.analista
    LEFT JOIN dim_calif dc ON dc.calificacion     = s.calificacion
    LEFT JOIN dim_fec   df ON df.full_date        = s.fecha_desembolso
    LEFT JOIN dim_fec   df2 ON df2.full_date      = s.fecha_ultimo_pago
)

SELECT * FROM fact
