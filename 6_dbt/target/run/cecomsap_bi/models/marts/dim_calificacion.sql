
  
    

  create  table "dw_cecomsap"."marts"."dim_calificacion__dbt_tmp"
  
  
    as
  
  (
    -- models/marts/dim_calificacion.sql
-- Dimensión Calificación SBS de riesgo crediticio



SELECT
    1  AS calif_id, 'NOR' AS calificacion,
    'Normal'           AS descripcion,
    0                  AS orden_riesgo,
    'Bajo'             AS nivel_riesgo,
    0.01               AS tasa_provision_referencial

UNION ALL SELECT
    2, 'POT', 'Con problemas potenciales', 1, 'Medio bajo', 0.05

UNION ALL SELECT
    3, 'DEF', 'Deficiente', 2, 'Medio', 0.25

UNION ALL SELECT
    4, 'DUD', 'Dudoso', 3, 'Alto', 0.60

UNION ALL SELECT
    5, 'PER', 'Pérdida', 4, 'Muy alto', 1.00
  );
  