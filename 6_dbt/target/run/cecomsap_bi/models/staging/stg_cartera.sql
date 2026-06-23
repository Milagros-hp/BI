
  create view "dw_cecomsap"."staging"."stg_cartera__dbt_tmp"
    
    
  as (
    -- models/staging/stg_cartera.sql
-- Capa Silver: limpieza, renombrado y estandarización de raw.cartera
-- Fuente: raw.cartera (Kafka consumer desde MySQL OLTP)

WITH source AS (
    SELECT * FROM "dw_cecomsap"."raw"."cartera"
    WHERE cod IS NOT NULL
),

cleaned AS (
    SELECT
        -- ── Identificación ──────────────────────────────────
        TRIM(cod)                                  AS cod,
        TRIM(titular)                              AS titular,
        TRIM(di)                                   AS documento_identidad,

        -- ── Clasificación del crédito ───────────────────────
        TRIM(tcr)                                  AS tipo_credito,
        TRIM(prod)                                 AS producto,
        TRIM(codigo_credito)                       AS codigo_credito,
        TRIM(frec)                                 AS frecuencia_pago,

        -- ── Fechas ──────────────────────────────────────────
        fecha_desemb                               AS fecha_desembolso,
        fdmb_or                                    AS fecha_desembolso_original,
        fingreso                                   AS fecha_ingreso_socio,
        ultimo_pago                                AS fecha_ultimo_pago,
        fnacim                                     AS fecha_nacimiento,

        -- ── Condiciones del crédito ─────────────────────────
        COALESCE(od, 0)                            AS operacion_directa,
        COALESCE(monto_credito, 0)                 AS monto_credito,
        COALESCE(plazo, 0)                         AS plazo,
        COALESCE(tasa, 0)                          AS tasa_interes,
        COALESCE(cuota_ref, 0)                     AS cuota_referencia,
        COALESCE(cuot_pag, 0)                      AS cuotas_pagadas,
        cuota_pend                                 AS fecha_cuota_pendiente,

        -- ── Estado de la deuda ──────────────────────────────
        COALESCE(saldo_credito, 0)                 AS saldo_credito,
        COALESCE(capital_atraso, 0)                AS capital_atraso,
        COALESCE(interes, 0)                       AS interes_devengado,
        COALESCE(mora, 0)                          AS mora,
        COALESCE(total, 0)                         AS total_deuda,
        COALESCE(cap_venc, 0)                      AS capital_vencido,
        COALESCE(int_vnc, 0)                       AS interes_vencido,
        COALESCE(cuot_atrs, 0)                     AS cuotas_atraso,
        COALESCE(dias_atrs, 0)                     AS dias_atraso,

        -- ── Calificación y provisión ────────────────────────
        COALESCE(UPPER(TRIM(calif)), 'NOR')        AS calificacion,
        COALESCE(provision, 0)                     AS provision_cartera,

        -- ── Perfil del cliente ──────────────────────────────
        UPPER(TRIM(gen))                           AS genero,
        COALESCE(aporte, 0)                        AS aporte_socio,
        COALESCE(sald_ahorro, 0)                   AS saldo_ahorro,
        TRIM(tipo_viv)                             AS tipo_vivienda,
        TRIM(ubig)                                 AS ubigeo,
        TRIM(ley_laboral)                          AS ley_laboral,
        TRIM(centro_laboral)                       AS centro_laboral,
        TRIM(zona_laboral)                         AS zona_laboral,

        -- ── Gestión ─────────────────────────────────────────
        TRIM(gestor)                               AS gestor,
        TRIM(gestor_orig)                          AS gestor_origen,
        TRIM(analista)                             AS analista,
        TRIM(promotor)                             AS promotor,
        COALESCE(cc, 0)                            AS centro_costo,
        TRIM(COALESCE(excp, 'NO'))                 AS excepcion,
        TRIM(COALESCE(rurl, 'NO'))                 AS es_rural,
        TRIM(COALESCE(fndm, 'NO'))                 AS con_fondo,
        TRIM(COALESCE(cntg, 'NO'))                 AS contingencia,
        TRIM(telefono)                             AS telefono,

        -- ── Campos calculados ───────────────────────────────
        CASE
            WHEN dias_atrs = 0               THEN 'Al día'
            WHEN dias_atrs BETWEEN 1 AND 30  THEN '1-30 días'
            WHEN dias_atrs BETWEEN 31 AND 60 THEN '31-60 días'
            WHEN dias_atrs BETWEEN 61 AND 90 THEN '61-90 días'
            WHEN dias_atrs > 90              THEN 'Más de 90 días'
        END                                        AS bucket_atraso,

        DATE_PART('year', AGE(CURRENT_DATE, fnacim::date))::INT
                                                   AS edad,

        -- ── Metadata CDC ────────────────────────────────────
        _op                                        AS cdc_operacion,
        _cdc_ts                                    AS cdc_timestamp

    FROM source
    WHERE monto_credito > 0
      AND saldo_credito IS NOT NULL
)

SELECT * FROM cleaned
  );