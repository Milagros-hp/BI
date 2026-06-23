"""
consumer.py
Kafka → PostgreSQL raw.cartera
Lee mensajes del topic cecomsap.oltp_cecomsap.cartera
y hace UPSERT en la capa raw de PostgreSQL.
"""

import json
import os
import logging
from datetime import date, datetime, timedelta, timezone

import psycopg2
from psycopg2.extras import execute_values
from confluent_kafka import Consumer, KafkaError

EPOCH = date(1970, 1, 1)
DATE_FIELDS = ["fecha_desemb", "ultimo_pago", "cuota_pend",
               "fingreso", "fnacim", "fdmb_or"]


def _to_date(v):
    """Debezium con time.precision.mode=connect serializa DATE como int (días desde epoch)."""
    if v is None or v == "":
        return None
    if isinstance(v, int):
        return EPOCH + timedelta(days=v)
    return v

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)
log = logging.getLogger(__name__)

# ── Config ────────────────────────────────────────────────────
KAFKA_CFG = {
    "bootstrap.servers": os.getenv("KAFKA_BOOTSTRAP", "localhost:9092"),
    "group.id":          "cecomsap-raw-consumer",
    "auto.offset.reset": "earliest",
    "enable.auto.commit": False,
}

TOPIC = "cecomsap.oltp_cecomsap.cartera"

PG_DSN = (
    f"host={os.getenv('PG_HOST','localhost')} "
    f"port={os.getenv('PG_PORT','5432')} "
    f"dbname={os.getenv('PG_DATABASE','dw_cecomsap')} "
    f"user={os.getenv('PG_USER','dw_user')} "
    f"password={os.getenv('PG_PASSWORD','dw_pass123')}"
)

UPSERT_SQL = """
INSERT INTO raw.cartera (
    cod, titular, di, tcr, prod, codigo_credito, fecha_desemb,
    od, monto_credito, plazo, frec, tasa, saldo_credito, ultimo_pago,
    cuot_atrs, dias_atrs, capital_atraso, interes, mora, total,
    cap_venc, calif, provision, telefono, gestor, cuota_ref,
    cuota_pend, fingreso, sald_ahorro, fnacim, gen, aporte,
    excp, rurl, gestor_orig, cuot_pag, analista, promotor,
    cc, tipo_viv, fndm, ubig, int_vnc, cntg, fdmb_or,
    ley_laboral, centro_laboral, zona_laboral,
    _op, _cdc_ts
)
VALUES %s
ON CONFLICT (cod) DO UPDATE SET
    titular        = EXCLUDED.titular,
    saldo_credito  = EXCLUDED.saldo_credito,
    dias_atrs      = EXCLUDED.dias_atrs,
    capital_atraso = EXCLUDED.capital_atraso,
    mora           = EXCLUDED.mora,
    total          = EXCLUDED.total,
    calif          = EXCLUDED.calif,
    provision      = EXCLUDED.provision,
    ultimo_pago    = EXCLUDED.ultimo_pago,
    cuot_atrs      = EXCLUDED.cuot_atrs,
    sald_ahorro    = EXCLUDED.sald_ahorro,
    _op            = EXCLUDED._op,
    _cdc_ts        = EXCLUDED._cdc_ts;
"""

FIELDS = [
    "cod","titular","di","tcr","prod","codigo_credito","fecha_desemb",
    "od","monto_credito","plazo","frec","tasa","saldo_credito","ultimo_pago",
    "cuot_atrs","dias_atrs","capital_atraso","interes","mora","total",
    "cap_venc","calif","provision","telefono","gestor","cuota_ref",
    "cuota_pend","fingreso","sald_ahorro","fnacim","gen","aporte",
    "excp","rurl","gestor_orig","cuot_pag","analista","promotor",
    "cc","tipo_viv","fndm","ubig","int_vnc","cntg","fdmb_or",
    "ley_laboral","centro_laboral","zona_laboral"
]

def parse_message(msg_value: bytes) -> dict | None:
    try:
        payload = json.loads(msg_value)
        data    = payload.get("payload") or payload
        op      = data.get("__op", data.get("op", "r"))
        if op == "d":
            return None
        record = {f: data.get(f) for f in FIELDS}
        for f in DATE_FIELDS:
            record[f] = _to_date(record.get(f))
        record["_op"]     = op
        record["_cdc_ts"] = datetime.now(timezone.utc)
        return record
    except Exception as e:
        log.warning(f"Error parseando mensaje: {e}")
        return None

def record_to_tuple(r: dict) -> tuple:
    return tuple(r.get(f) for f in FIELDS + ["_op", "_cdc_ts"])

def main():
    log.info("Conectando a PostgreSQL...")
    pg_conn = psycopg2.connect(PG_DSN)
    pg_cur  = pg_conn.cursor()

    log.info(f"Suscribiendo a topic: {TOPIC}")
    consumer = Consumer(KAFKA_CFG)
    consumer.subscribe([TOPIC])

    batch, batch_size = [], 100
    processed = 0

    try:
        while True:
            msg = consumer.poll(timeout=1.0)

            if msg is None:
                if batch:
                    try:
                        execute_values(pg_cur, UPSERT_SQL, batch)
                        pg_conn.commit()
                        consumer.commit()
                        processed += len(batch)
                        log.info(f"Flush: {len(batch)} registros — total {processed}")
                    except Exception as e:
                        pg_conn.rollback()
                        log.error(f"Flush fallido ({len(batch)} reg): {e}")
                        raise
                    batch = []
                continue

            if msg.error():
                err_code = msg.error().code()
                if err_code == KafkaError._PARTITION_EOF:
                    continue
                if err_code in (KafkaError.UNKNOWN_TOPIC_OR_PART,
                                KafkaError._UNKNOWN_TOPIC):
                    # Topic aún no creado por Debezium — esperamos
                    log.info("Topic aún no disponible; esperando a Debezium...")
                    continue
                log.error(f"Kafka error: {msg.error()}")
                break

            record = parse_message(msg.value())
            if record:
                batch.append(record_to_tuple(record))

            if len(batch) >= batch_size:
                try:
                    execute_values(pg_cur, UPSERT_SQL, batch)
                    pg_conn.commit()
                    consumer.commit()
                    processed += len(batch)
                    log.info(f"Commit: {len(batch)} registros — total {processed}")
                except Exception as e:
                    pg_conn.rollback()
                    log.error(f"Batch fallido ({len(batch)} reg): {e}")
                    raise
                batch = []

    except KeyboardInterrupt:
        log.info("Consumer detenido por el usuario")
    finally:
        if batch:
            execute_values(pg_cur, UPSERT_SQL, batch)
            pg_conn.commit()
        pg_cur.close()
        pg_conn.close()
        consumer.close()
        log.info(f"Consumer cerrado. Total procesado: {processed}")

if __name__ == "__main__":
    main()
