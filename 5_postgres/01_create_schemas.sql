-- ============================================================
-- CECOMSAP DataWarehouse · Creación de schemas
-- raw (Bronze) | staging (Silver) | marts (Gold)
-- ============================================================

-- PostgreSQL no tiene COMMENT en CREATE SCHEMA directamente
-- se usa COMMENT ON SCHEMA
CREATE SCHEMA IF NOT EXISTS raw;
COMMENT ON SCHEMA raw     IS 'Bronze: réplica exacta desde Kafka consumer';

CREATE SCHEMA IF NOT EXISTS staging;
COMMENT ON SCHEMA staging IS 'Silver: datos limpios y estandarizados por dbt';

CREATE SCHEMA IF NOT EXISTS marts;
COMMENT ON SCHEMA marts   IS 'Gold: modelo dimensional listo para Power BI';
