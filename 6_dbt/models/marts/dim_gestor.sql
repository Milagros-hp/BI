-- models/marts/dim_gestor.sql
-- Dimensión Gestor: gestores, analistas y promotores

{{ config(materialized='table') }}

WITH gestores AS (
    SELECT DISTINCT
        COALESCE(TRIM(gestor), 'SIN GESTOR')         AS gestor,
        COALESCE(TRIM(gestor_origen), 'SIN GESTOR')  AS gestor_origen,
        COALESCE(TRIM(analista), 'SIN ANALISTA')     AS analista
    FROM {{ ref('stg_cartera') }}
)

SELECT
    ROW_NUMBER() OVER (ORDER BY gestor)  AS gestor_id,
    gestor,
    gestor_origen,
    analista,
    CASE WHEN gestor = gestor_origen
         THEN TRUE ELSE FALSE END        AS es_gestor_original
FROM gestores
