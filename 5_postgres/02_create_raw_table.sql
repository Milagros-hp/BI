-- ============================================================
-- CECOMSAP · Tabla raw.cartera
-- Destino directo del Kafka consumer — sin transformaciones
-- ============================================================

CREATE TABLE IF NOT EXISTS raw.cartera (
    cod              VARCHAR(20)    NOT NULL,
    titular          VARCHAR(150),
    di               VARCHAR(20),
    tcr              VARCHAR(10),
    prod             VARCHAR(80),
    codigo_credito   VARCHAR(30),
    fecha_desemb     DATE,
    od               SMALLINT,
    monto_credito    NUMERIC(14,2),
    plazo            SMALLINT,
    frec             VARCHAR(20),
    tasa             NUMERIC(8,4),
    saldo_credito    NUMERIC(14,2),
    ultimo_pago      DATE,
    cuot_atrs        SMALLINT,
    dias_atrs        SMALLINT,
    capital_atraso   NUMERIC(14,2),
    interes          NUMERIC(14,2),
    mora             NUMERIC(14,2),
    total            NUMERIC(14,2),
    cap_venc         NUMERIC(14,2),
    calif            VARCHAR(5),
    provision        NUMERIC(14,2),
    telefono         VARCHAR(20),
    gestor           VARCHAR(30),
    cuota_ref        NUMERIC(10,2),
    cuota_pend       DATE,
    fingreso         DATE,
    sald_ahorro      NUMERIC(14,2),
    fnacim           DATE,
    gen              CHAR(1),
    aporte           NUMERIC(10,2),
    excp             VARCHAR(5),
    rurl             VARCHAR(5),
    gestor_orig      VARCHAR(30),
    cuot_pag         SMALLINT,
    analista         VARCHAR(30),
    promotor         VARCHAR(30),
    cc               SMALLINT,
    tipo_viv         VARCHAR(20),
    fndm             VARCHAR(5),
    ubig             VARCHAR(10),
    int_vnc          NUMERIC(14,2),
    cntg             VARCHAR(5),
    fdmb_or          DATE,
    ley_laboral      VARCHAR(30),
    centro_laboral   VARCHAR(80),
    zona_laboral     VARCHAR(80),
    -- Metadatos CDC
    _op              CHAR(1),
    _cdc_ts          TIMESTAMP      DEFAULT NOW(),
    PRIMARY KEY (cod)
);

COMMENT ON COLUMN raw.cartera._op IS 'c=create, u=update, d=delete, r=read/snapshot';

-- Índices para consultas de validación y dbt
CREATE INDEX IF NOT EXISTS idx_raw_calif   ON raw.cartera(calif);
CREATE INDEX IF NOT EXISTS idx_raw_gestor  ON raw.cartera(gestor);
CREATE INDEX IF NOT EXISTS idx_raw_tcr     ON raw.cartera(tcr);
CREATE INDEX IF NOT EXISTS idx_raw_cdc_ts  ON raw.cartera(_cdc_ts);
