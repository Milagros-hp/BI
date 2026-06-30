# Trazabilidad Fuente → Modelo → KPI → Dashboard

## 12. Trazabilidad Fuente → Modelo → KPI → Dashboard

La matriz conecta cada KPI desde la columna de origen en MySQL hasta el visual en Power BI, pasando por cada capa. Permite verificar de dónde proviene exactamente cada cifra.

| # | KPI | Columna OLTP (MySQL) | Campo marts (PostgreSQL) | Medida DAX | Visual Power BI |
|---|---|---|---|---|---|
| 1 | Saldo Vigente Total | cartera.saldo_credito | fact_cartera.saldo_credito | Saldo Vigente Total | Tarjeta KPI — pág. Cartera General |
| 2 | Capital en Mora | cartera.capital_atraso | fact_cartera.capital_atraso | Capital en Mora | Tarjeta KPI — pág. Cartera General |
| 3 | Índice de Morosidad % | capital_atraso / saldo_credito | fact_cartera.tasa_morosidad_pct | Índice de Morosidad % | Tarjeta + semáforo — pág. Cartera General |
| 4 | Provisión Total | cartera.provision | fact_cartera.provision_cartera | Provisión Total | Tarjeta KPI — pág. Cartera General |
| 5 | Cobertura Provisión % | provision / capital_atraso | calculado en DAX | Cobertura Provisión % | Medidor — pág. Cartera General |
| 6 | % Cartera en Riesgo | cartera.calif IN (PER,DUD,DEF,POT) | dim_calificacion + fact_cartera | % Cartera en Riesgo | Barras apiladas — pág. Cartera General |

> **Valor del producto — Trazabilidad completa:** Cualquier cifra del dashboard puede rastrearse hasta la columna exacta de MySQL. La ruta es: `cartera.columna → raw.cartera → stg_cartera → fact_cartera → medida DAX → visual Power BI`.

---

## Anexo A — Glosario de Negocio

| Término | Definición |
|---|---|
| Saldo vigente | Monto pendiente de pago del crédito al corte de análisis (31/03/2026) |
| Capital en mora | Parte del capital que ya venció y no fue pagada |
| Índice de morosidad | Capital en mora / Saldo vigente total × 100 (en %) |
| Provisión | Reserva contable para cubrir posibles pérdidas por incobrabilidad |
| Calificación SBS | NOR = Normal, POT = Con Problemas Potenciales, DEF = Deficiente, DUD = Dudoso, PER = Pérdida |
| Bucket de atraso | Segmento de días de mora: Al día / 1-30 / 31-60 / 61-90 / >90 días |
| CDC | Change Data Capture: captura cada cambio en MySQL en tiempo real vía binlog |
| Grano del DataMart | Un crédito por fila, al corte del 31/03/2026 |

---

## Anexo B — Mapa de Evidencias en el Repositorio

| Evidencia | Ruta en el repositorio |
|---|---|
| Loader Excel → MySQL | `1_data/load_to_mysql.py` + BD MARZO26.xlsx |
| Tabla OLTP MySQL | `2_mysql/01_create_oltp_table.sql` |
| Conector Debezium | `3_debezium/connector-config.json` |
| Consumer Kafka → PostgreSQL | `4_consumer/consumer.py` |
| Esquemas PostgreSQL | `5_postgres/01_create_schemas.sql` + `02_create_raw_table.sql` |
| Staging dbt | `6_dbt/models/staging/stg_cartera.sql` + `stg_cartera.yml` |
| Marts dbt (dims + fact) | `6_dbt/models/marts/` (6 archivos .sql) |
| KPIs SQL de validación | `7_validacion/04_kpis_analiticos.sql` |
| Medidas DAX | `8_powerbi/medidas_dax.md` |
| Guía de ejecución completa | `COMO_CORRER_TODO.md` |
| Docker Compose | `docker-compose.yml` |
| Documentación MkDocs | `docs/` + `mkdocs.yml` |

---

## 18. Conclusiones

- El DataMart soporta los 6 KPIs definidos, calculados directamente desde `marts.fact_cartera` sin cálculos manuales ni Excel.
- La separación física entre OLTP (MySQL) y Data Warehouse (PostgreSQL) es real y verificable: contenedores Docker independientes con Debezium+Kafka como único puente CDC.
- El pipeline captura cambios en tiempo real y se detiene automáticamente ante un error de calidad (dbt test), antes de que lleguen a Power BI.
- Las medidas DAX coinciden exactamente con el SQL del DataMart (diferencia cero en los 6 KPIs), confirmando la integridad de cada capa.
- El hallazgo más crítico es la concentración de mora en el bucket 31-60 días: es el punto de intervención más eficiente porque los créditos aún son recuperables con cobranza activa antes de migrar a PER.
- Los comparativos de año anterior y mes anterior dotan al dashboard de capacidad de seguimiento de tendencia crediticia — exigencia obligatoria de la Unidad 3.
