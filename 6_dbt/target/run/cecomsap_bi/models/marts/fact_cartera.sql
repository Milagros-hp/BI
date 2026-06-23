
      
        
        
        delete from "dw_cecomsap"."marts"."fact_cartera" as DBT_INTERNAL_DEST
        where (cod) in (
            select distinct cod
            from "fact_cartera__dbt_tmp024628484594" as DBT_INTERNAL_SOURCE
        );

    

    insert into "dw_cecomsap"."marts"."fact_cartera" ("cod", "customer_id", "product_id", "gestor_id", "calif_id", "date_id_desembolso", "date_id_ultimo_pago", "codigo_credito", "tipo_credito", "producto", "frecuencia_pago", "operacion_directa", "plazo", "tasa_interes", "bucket_atraso", "fecha_desembolso", "fecha_ultimo_pago", "fecha_cuota_pendiente", "monto_credito", "saldo_credito", "capital_atraso", "interes_devengado", "mora", "total_deuda", "capital_vencido", "interes_vencido", "provision_cartera", "cuota_referencia", "saldo_ahorro", "dias_atraso", "cuotas_atraso", "cuotas_pagadas", "pct_saldo_vs_desembolso", "tasa_morosidad_pct", "fecha_corte", "cdc_operacion", "cdc_timestamp")
    (
        select "cod", "customer_id", "product_id", "gestor_id", "calif_id", "date_id_desembolso", "date_id_ultimo_pago", "codigo_credito", "tipo_credito", "producto", "frecuencia_pago", "operacion_directa", "plazo", "tasa_interes", "bucket_atraso", "fecha_desembolso", "fecha_ultimo_pago", "fecha_cuota_pendiente", "monto_credito", "saldo_credito", "capital_atraso", "interes_devengado", "mora", "total_deuda", "capital_vencido", "interes_vencido", "provision_cartera", "cuota_referencia", "saldo_ahorro", "dias_atraso", "cuotas_atraso", "cuotas_pagadas", "pct_saldo_vs_desembolso", "tasa_morosidad_pct", "fecha_corte", "cdc_operacion", "cdc_timestamp"
        from "fact_cartera__dbt_tmp024628484594"
    )
  