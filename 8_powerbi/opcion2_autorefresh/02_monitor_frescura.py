"""
02_monitor_frescura.py
Monitorea que el pipeline esté vivo:
  - Verifica que raw.cartera recibe datos de Kafka
  - Verifica que dbt corrió exitosamente
  - Registra en marts.refresh_log
  - Envía alerta si los datos tienen más de N minutos sin actualizar
Ejecutar: python 02_monitor_frescura.py  (puede correrse como cron)
"""

import os
import time
import logging
import subprocess
import smtplib
from email.mime.text import MIMEText
from datetime import datetime, timedelta

import psycopg2
from psycopg2.extras import RealDictCursor

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)
log = logging.getLogger(__name__)

# ── Config ────────────────────────────────────────────────────
PG_DSN = (
    f"host={os.getenv('PG_HOST','localhost')} "
    f"port={os.getenv('PG_PORT','5432')} "
    f"dbname={os.getenv('PG_DATABASE','dw_cecomsap')} "
    f"user={os.getenv('PG_USER','dw_user')} "
    f"password={os.getenv('PG_PASSWORD','dw_pass123')}"
)

DBT_PROJECT_DIR = os.path.join(
    os.path.dirname(__file__), "..", "..", "6_dbt"
)

# Alerta si raw.cartera no se actualiza en más de estos minutos
STALE_THRESHOLD_MIN = 60

# Config email (opcional)
SMTP_HOST    = os.getenv("SMTP_HOST", "")
SMTP_PORT    = int(os.getenv("SMTP_PORT", "587"))
SMTP_USER    = os.getenv("SMTP_USER", "")
SMTP_PASS    = os.getenv("SMTP_PASS", "")
ALERT_TO     = os.getenv("ALERT_EMAIL", "")


# ── Helpers ───────────────────────────────────────────────────
def get_conn():
    return psycopg2.connect(PG_DSN, cursor_factory=RealDictCursor)

def log_refresh(conn, fuente, registros, duracion, estado, detalle=""):
    with conn.cursor() as cur:
        cur.execute("""
            INSERT INTO marts.refresh_log
                (fuente, registros, duracion_seg, estado, detalle)
            VALUES (%s, %s, %s, %s, %s)
        """, (fuente, registros, duracion, estado, detalle))
    conn.commit()

def send_alert(subject: str, body: str):
    if not SMTP_HOST or not ALERT_TO:
        log.warning("SMTP no configurado — alerta solo en consola")
        log.warning(f"ALERTA: {subject}\n{body}")
        return
    msg = MIMEText(body)
    msg["Subject"] = f"[CECOMSAP BI] {subject}"
    msg["From"]    = SMTP_USER
    msg["To"]      = ALERT_TO
    try:
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as s:
            s.starttls()
            s.login(SMTP_USER, SMTP_PASS)
            s.send_message(msg)
        log.info(f"Alerta enviada a {ALERT_TO}")
    except Exception as e:
        log.error(f"Error enviando alerta: {e}")


# ── Checks ────────────────────────────────────────────────────
def check_raw_frescura(conn) -> dict:
    """Verifica que raw.cartera tenga datos recientes."""
    with conn.cursor() as cur:
        cur.execute("""
            SELECT
                COUNT(*)              AS total,
                MAX(_cdc_ts)          AS ultima_actualizacion,
                NOW() - MAX(_cdc_ts)  AS antiguedad
            FROM raw.cartera
        """)
        row = dict(cur.fetchone())

    antiguedad_min = row["antiguedad"].total_seconds() / 60 if row["antiguedad"] else 9999
    row["antiguedad_min"] = round(antiguedad_min, 1)
    row["fresca"]         = antiguedad_min < STALE_THRESHOLD_MIN
    return row

def check_marts_frescura(conn) -> dict:
    """Verifica que marts.fact_cartera tenga datos."""
    with conn.cursor() as cur:
        cur.execute("""
            SELECT
                COUNT(*)              AS total_fact,
                MAX(cdc_timestamp)    AS ultima_actualizacion,
                NOW() - MAX(cdc_timestamp) AS antiguedad
            FROM marts.fact_cartera
        """)
        row = dict(cur.fetchone())

    antiguedad_min = row["antiguedad"].total_seconds() / 60 if row["antiguedad"] else 9999
    row["antiguedad_min"] = round(antiguedad_min, 1)
    row["fresca"]         = antiguedad_min < STALE_THRESHOLD_MIN * 2
    return row

def check_kpis(conn) -> dict:
    """Extrae KPIs clave para verificar consistencia."""
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM marts.vw_kpis_resumen")
        return dict(cur.fetchone())

def run_dbt(modelo: str = "") -> tuple[bool, float, str]:
    """Ejecuta dbt run y devuelve (éxito, segundos, output)."""
    cmd = ["dbt", "run"]
    if modelo:
        cmd += ["--select", modelo]

    t0 = time.time()
    try:
        result = subprocess.run(
            cmd,
            cwd=DBT_PROJECT_DIR,
            capture_output=True,
            text=True,
            timeout=300
        )
        dur = time.time() - t0
        ok  = result.returncode == 0
        out = result.stdout[-2000:] if result.stdout else result.stderr[-2000:]
        return ok, dur, out
    except subprocess.TimeoutExpired:
        return False, time.time() - t0, "dbt timeout después de 300s"
    except FileNotFoundError:
        return False, 0, "dbt no encontrado — instala con: pip install dbt-postgres"

def run_dbt_test() -> tuple[bool, str]:
    """Ejecuta dbt test y devuelve (éxito, output)."""
    try:
        result = subprocess.run(
            ["dbt", "test"],
            cwd=DBT_PROJECT_DIR,
            capture_output=True,
            text=True,
            timeout=120
        )
        return result.returncode == 0, result.stdout[-1500:]
    except Exception as e:
        return False, str(e)


# ── Pipeline de refresco completo ────────────────────────────
def run_refresh_cycle():
    log.info("=" * 55)
    log.info(f"Ciclo de refresco — {datetime.now():%Y-%m-%d %H:%M:%S}")
    log.info("=" * 55)

    conn = get_conn()
    alertas = []

    # 1. Verificar frescura de raw
    log.info("[1/4] Verificando raw.cartera ...")
    raw = check_raw_frescura(conn)
    log.info(f"      Total: {raw['total']} filas | "
             f"Última actualización: {raw['ultima_actualizacion']} | "
             f"Antigüedad: {raw['antiguedad_min']} min")
    if not raw["fresca"]:
        msg = f"raw.cartera sin actualizar hace {raw['antiguedad_min']} min (umbral: {STALE_THRESHOLD_MIN})"
        log.warning(f"      ALERTA: {msg}")
        alertas.append(msg)
    log_refresh(conn, "kafka_consumer", raw["total"],
                0, "OK" if raw["fresca"] else "WARN",
                f"Antigüedad: {raw['antiguedad_min']} min")

    # 2. Ejecutar dbt run
    log.info("[2/4] Ejecutando dbt run ...")
    t0  = time.time()
    ok, dur, output = run_dbt()
    log.info(f"      {'OK' if ok else 'ERROR'} en {dur:.1f}s")
    if not ok:
        alertas.append(f"dbt run falló: {output[-300:]}")
        log.error(f"      Output: {output[-500:]}")
    log_refresh(conn, "dbt_run", 0, round(dur, 2),
                "OK" if ok else "ERROR", output[-500:])

    # 3. Ejecutar dbt test
    if ok:
        log.info("[3/4] Ejecutando dbt test ...")
        test_ok, test_out = run_dbt_test()
        log.info(f"      Tests: {'PASS' if test_ok else 'FAIL'}")
        if not test_ok:
            alertas.append(f"dbt test con errores: {test_out[-200:]}")
    else:
        log.info("[3/4] Saltando dbt test (dbt run falló)")

    # 4. Verificar marts y KPIs
    log.info("[4/4] Verificando marts.fact_cartera y KPIs ...")
    marts = check_marts_frescura(conn)
    kpis  = check_kpis(conn)
    log.info(f"      fact_cartera: {marts['total_fact']} filas")
    log.info(f"      Saldo vigente: S/ {kpis['saldo_vigente_total']:,.2f}")
    log.info(f"      Índice mora:   {kpis['indice_morosidad_pct']}%")
    log.info(f"      Última act.:   {kpis['ultima_actualizacion']}")
    log_refresh(conn, "dbt_run", marts["total_fact"],
                0, "OK" if marts["fresca"] else "WARN",
                f"Saldo: {kpis['saldo_vigente_total']} | Mora: {kpis['indice_morosidad_pct']}%")

    # Enviar alertas si hubo problemas
    if alertas:
        send_alert(
            subject="Pipeline con errores",
            body="\n\n".join(alertas) +
                 f"\n\nFecha: {datetime.now():%Y-%m-%d %H:%M:%S}"
        )

    conn.close()
    log.info(f"Ciclo completado — {len(alertas)} alerta(s)")
    return len(alertas) == 0


# ── Modo daemon (bucle continuo) ─────────────────────────────
def run_daemon(intervalo_min: int = 30):
    """Corre el ciclo de refresco cada N minutos."""
    log.info(f"Iniciando daemon — refresco cada {intervalo_min} min")
    while True:
        try:
            run_refresh_cycle()
        except Exception as e:
            log.error(f"Error en ciclo: {e}")
            send_alert("Error crítico en pipeline", str(e))
        log.info(f"Esperando {intervalo_min} min para el próximo ciclo ...")
        time.sleep(intervalo_min * 60)


if __name__ == "__main__":
    import sys
    if "--daemon" in sys.argv:
        intervalo = int(os.getenv("REFRESH_INTERVAL_MIN", "30"))
        run_daemon(intervalo)
    else:
        success = run_refresh_cycle()
        sys.exit(0 if success else 1)
