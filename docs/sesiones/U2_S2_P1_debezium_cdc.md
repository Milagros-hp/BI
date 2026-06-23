# S2 P1 — Debezium CDC replica MySQL PostgreSQL

Configuración del conector Debezium: `3_debezium/connector-config.json`.

Topic publicado: `cecomsap.oltp_cecomsap.cartera` (según la configuración y `COMO_CORRER_TODO.md`).

Debezium usa `ExtractNewRecordState` para "unwrap" de mensajes y agrega campos `op` y `ts_ms`.
