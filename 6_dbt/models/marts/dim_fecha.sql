-- models/marts/dim_fecha.sql
-- Dimensión Fecha generada desde las fechas de desembolso de la cartera

{{ config(materialized='table') }}

WITH fechas AS (
    SELECT DISTINCT fecha_desembolso AS fecha
    FROM {{ ref('stg_cartera') }}
    WHERE fecha_desembolso IS NOT NULL

    UNION

    SELECT DISTINCT fecha_ultimo_pago
    FROM {{ ref('stg_cartera') }}
    WHERE fecha_ultimo_pago IS NOT NULL
),

dim AS (
    SELECT
        TO_CHAR(fecha, 'YYYYMMDD')::INT          AS date_id,
        fecha                                     AS full_date,
        DATE_PART('day',   fecha)::INT            AS dia,
        DATE_PART('month', fecha)::INT            AS mes,
        TO_CHAR(fecha, 'Month')                   AS nombre_mes,
        DATE_PART('quarter', fecha)::INT          AS trimestre,
        'Q' || DATE_PART('quarter', fecha)::INT   AS nombre_trimestre,
        DATE_PART('year', fecha)::INT             AS anio,
        DATE_PART('isodow', fecha)::INT           AS dia_semana,
        TO_CHAR(fecha, 'Day')                     AS nombre_dia,
        CASE WHEN DATE_PART('isodow', fecha) IN (6,7)
             THEN TRUE ELSE FALSE END             AS es_fin_semana,
        DATE_TRUNC('month', fecha)::DATE          AS primer_dia_mes,
        (DATE_TRUNC('month', fecha) + INTERVAL '1 month - 1 day')::DATE
                                                  AS ultimo_dia_mes
    FROM fechas
)

SELECT * FROM dim
ORDER BY date_id
