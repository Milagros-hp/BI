
  
    

  create  table "dw_cecomsap"."marts"."dim_cliente__dbt_tmp"
  
  
    as
  
  (
    -- models/marts/dim_cliente.sql
-- Dimensión Cliente: perfil del titular del crédito



WITH clientes AS (
    SELECT DISTINCT ON (cod)
        cod,
        titular,
        documento_identidad,
        fecha_nacimiento,
        genero,
        tipo_vivienda,
        ubigeo,
        ley_laboral,
        centro_laboral,
        zona_laboral,
        fecha_ingreso_socio,
        aporte_socio,
        es_rural,
        edad
    FROM "dw_cecomsap"."staging"."stg_cartera"
    WHERE cod IS NOT NULL
    ORDER BY cod, cdc_timestamp DESC
)

SELECT
    cod                                            AS customer_id,
    titular,
    documento_identidad,
    fecha_nacimiento,
    COALESCE(edad, 0)                             AS edad,

    -- Rango etario
    CASE
        WHEN edad < 25               THEN 'Joven (< 25)'
        WHEN edad BETWEEN 25 AND 35  THEN 'Adulto joven (25-35)'
        WHEN edad BETWEEN 36 AND 50  THEN 'Adulto (36-50)'
        WHEN edad BETWEEN 51 AND 65  THEN 'Adulto mayor (51-65)'
        WHEN edad > 65               THEN 'Senior (> 65)'
        ELSE 'Sin dato'
    END                                           AS rango_etario,

    CASE genero
        WHEN 'M' THEN 'Masculino'
        WHEN 'F' THEN 'Femenino'
        WHEN 'E' THEN 'Empresa/Jurídico'
        ELSE 'No especificado'
    END                                           AS genero,

    COALESCE(tipo_vivienda, 'Sin dato')           AS tipo_vivienda,

    -- Ubigeo → Región (primeros 2 dígitos = departamento)
    ubigeo,
    CASE LEFT(COALESCE(ubigeo,''), 2)
        WHEN '21' THEN 'Puno'
        WHEN '01' THEN 'Amazonas'
        WHEN '02' THEN 'Áncash'
        WHEN '03' THEN 'Apurímac'
        WHEN '15' THEN 'Lima'
        ELSE 'Otra región'
    END                                           AS region,

    COALESCE(ley_laboral,    'NINGUNA')           AS ley_laboral,
    COALESCE(centro_laboral, 'NINGUNO')           AS centro_laboral,
    COALESCE(zona_laboral,   'Sin zona')          AS zona_laboral,
    fecha_ingreso_socio,
    COALESCE(aporte_socio, 0)                     AS aporte_socio,
    CASE WHEN es_rural = 'SI' THEN TRUE ELSE FALSE END AS es_rural

FROM clientes
  );
  