-- models/marts/dim_producto.sql
-- Dimensión Producto: tipo de crédito + producto + frecuencia



WITH productos AS (
    SELECT DISTINCT
        tipo_credito,
        producto,
        frecuencia_pago
    FROM "dw_cecomsap"."staging"."stg_cartera"
    WHERE tipo_credito IS NOT NULL
      AND producto      IS NOT NULL
),

dim AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY tipo_credito, producto) AS product_id,
        tipo_credito,
        producto,
        frecuencia_pago,

        -- Etiqueta legible del tipo
        CASE tipo_credito
            WHEN 'MIE' THEN 'Microempresa'
            WHEN 'CON' THEN 'Consumo'
            WHEN 'PEE' THEN 'Pequeña empresa'
            WHEN 'MEE' THEN 'Mediana empresa'
            ELSE tipo_credito
        END                                  AS descripcion_tipo,

        -- Familia de producto
        CASE
            WHEN producto ILIKE '%DIARIO%'          THEN 'Crédito diario'
            WHEN producto ILIKE '%CAPITAL%'         THEN 'Capital de trabajo'
            WHEN producto ILIKE '%MAQUINARIA%'      THEN 'Activo fijo'
            WHEN producto ILIKE '%CONSUMO%'         THEN 'Consumo'
            WHEN producto ILIKE '%PYME%'            THEN 'PYME'
            WHEN producto ILIKE '%MICROEMPRES%'     THEN 'Microempresario'
            WHEN producto ILIKE '%CONVENIO%'        THEN 'Convenio'
            ELSE 'Otros'
        END                                  AS familia_producto
    FROM productos
)

SELECT * FROM dim