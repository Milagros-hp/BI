-- ============================================================
-- CECOMSAP · Tabla OLTP en MySQL
-- Fuente: BD_MARZO26.xlsx · Cartera al 31/03/2026
-- ============================================================

CREATE DATABASE IF NOT EXISTS oltp_cecomsap
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE oltp_cecomsap;

-- Permiso a Debezium para CDC
GRANT SELECT, RELOAD, SHOW DATABASES,
      REPLICATION SLAVE, REPLICATION CLIENT
ON *.* TO 'debezium'@'%';
FLUSH PRIVILEGES;

-- ─── Tabla principal de cartera ──────────────────────────────
CREATE TABLE IF NOT EXISTS cartera (
    cod              VARCHAR(20)    NOT NULL PRIMARY KEY COMMENT 'Código socio',
    titular          VARCHAR(150)   COMMENT 'Nombre completo del titular',
    di               VARCHAR(20)    COMMENT 'Documento de identidad',
    tcr              VARCHAR(10)    COMMENT 'Tipo de crédito: MIE, CON, PEE, MEE',
    prod             VARCHAR(80)    COMMENT 'Nombre del producto crediticio',
    codigo_credito   VARCHAR(30)    COMMENT 'Código interno del crédito',
    fecha_desemb     DATE           COMMENT 'Fecha de desembolso',
    od               TINYINT        COMMENT 'Operación directa (1=sí)',
    monto_credito    DECIMAL(14,2)  COMMENT 'Monto original desembolsado (S/)',
    plazo            SMALLINT       COMMENT 'Plazo en unidades de frecuencia',
    frec             VARCHAR(20)    COMMENT 'Frecuencia de pago: MESES, SEMANAS, etc.',
    tasa             DECIMAL(8,4)   COMMENT 'Tasa de interés mensual (%)',
    saldo_credito    DECIMAL(14,2)  COMMENT 'Saldo vigente al corte (S/)',
    ultimo_pago      DATE           COMMENT 'Fecha del último pago registrado',
    cuot_atrs        SMALLINT       COMMENT 'Número de cuotas en atraso',
    dias_atrs        SMALLINT       COMMENT 'Días de atraso acumulados',
    capital_atraso   DECIMAL(14,2)  COMMENT 'Capital vencido no pagado (S/)',
    interes          DECIMAL(14,2)  COMMENT 'Intereses devengados (S/)',
    mora             DECIMAL(14,2)  COMMENT 'Intereses por mora (S/)',
    total            DECIMAL(14,2)  COMMENT 'Total deuda (capital + interés + mora)',
    cap_venc         DECIMAL(14,2)  COMMENT 'Capital vencido (S/)',
    calif            VARCHAR(5)     COMMENT 'Calificación: NOR, PER, POT, DUD',
    provision        DECIMAL(14,2)  COMMENT 'Provisión de cartera (S/)',
    telefono         VARCHAR(20)    COMMENT 'Teléfono del titular',
    gestor           VARCHAR(30)    COMMENT 'Gestor actual',
    cuota_ref        DECIMAL(10,2)  COMMENT 'Cuota de referencia (S/)',
    cuota_pend       DATE           COMMENT 'Fecha de cuota pendiente',
    fingreso         DATE           COMMENT 'Fecha de ingreso como socio',
    sald_ahorro      DECIMAL(14,2)  COMMENT 'Saldo en cuenta de ahorro (S/)',
    fnacim           DATE           COMMENT 'Fecha de nacimiento',
    gen              CHAR(1)        COMMENT 'Género: M, F, E',
    aporte           DECIMAL(10,2)  COMMENT 'Aporte como socio (S/)',
    excp             VARCHAR(5)     COMMENT 'Excepción (SI/NO)',
    rurl             VARCHAR(5)     COMMENT 'Rural (SI/NO)',
    gestor_orig      VARCHAR(30)    COMMENT 'Gestor de origen del crédito',
    cuot_pag         SMALLINT       COMMENT 'Cuotas pagadas',
    analista         VARCHAR(30)    COMMENT 'Analista responsable',
    promotor         VARCHAR(30)    COMMENT 'Promotor del crédito',
    cc               SMALLINT       COMMENT 'Centro de costo',
    tipo_viv         VARCHAR(20)    COMMENT 'Tipo de vivienda: Propia, Alquilada, Padres',
    fndm             VARCHAR(5)     COMMENT 'Fondo: SI/NO',
    ubig             VARCHAR(10)    COMMENT 'Ubigeo INEI',
    int_vnc          DECIMAL(14,2)  COMMENT 'Interés vencido (S/)',
    cntg             VARCHAR(5)     COMMENT 'Contingencia: SI/NO',
    fdmb_or          DATE           COMMENT 'Fecha desembolso original',
    ley_laboral      VARCHAR(30)    COMMENT 'Régimen laboral',
    centro_laboral   VARCHAR(80)    COMMENT 'Centro de trabajo',
    zona_laboral     VARCHAR(80)    COMMENT 'Zona laboral',
    _cdc_ts          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
                                   COMMENT 'Timestamp CDC para Debezium incremental',
    KEY idx_calif  (calif),
    KEY idx_gestor (gestor),
    KEY idx_fecha  (fecha_desemb),
    KEY idx_tcr    (tcr),
    KEY idx_cdc    (_cdc_ts)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='Cartera de créditos CECOMSAP al 31/03/2026';
