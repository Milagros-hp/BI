"""
04_orquestador.py
Orquesta el ciclo completo de refresco automático:

  Cada N minutos:
  1. Verifica frescura de datos en raw.cartera
  2. Ejecuta dbt run + dbt test
  3. Llama a la API de Power BI para disparar el refresco
  4. Registra todo en marts.refresh_log
  5. Alerta por email si algo falla

Uso:
  # Correr una vez
  python 04_orquestador.py --once

  # Correr como daemon (cada 30 min por defecto)
  python 04_orquestador.py --daemon

  # Intervalo personalizado (cada 60 min)
  python 04_orquestador.py --daemon --intervalo 60

Cron equivalente (cada 30 minutos):
  */30 * * * * cd /ruta/proyecto && python 04_orquestador.py --once >> logs/orquestador.log 2>&1
"""

import argparse
import logging
import sys
import time
from datetime import datetime

# Importar los módulos del proyecto
sys.path.insert(0, __file__.rsplit("/", 1)[0])

log = logging.getLogger(__name__)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler("logs/orquestador.log", mode="a"),
    ]
)


def run_cycle(trigger_pbi: bool = True) -> bool:
    """Ejecuta un ciclo completo de refresco."""
    import importlib
    monitor = importlib.import_module("02_monitor_frescura")
    trigger = importlib.import_module("03_pbi_refresh_trigger")

    log.info("=" * 60)
    log.info(f"CICLO ORQUESTADOR — {datetime.now():%Y-%m-%d %H:%M:%S}")
    log.info("=" * 60)

    # Paso 1-4: Monitor (raw check + dbt run + dbt test + marts check)
    pipeline_ok = monitor.run_refresh_cycle()

    # Paso 5: Refresco Power BI (solo si pipeline está OK)
    pbi_ok = True
    if pipeline_ok and trigger_pbi:
        log.info("[5/5] Disparando refresco en Power BI Service ...")
        pbi_ok = trigger.full_refresh_cycle()
    elif not pipeline_ok:
        log.warning("[5/5] Saltando refresco PBI — pipeline con errores")

    resultado = pipeline_ok and pbi_ok
    log.info(f"Ciclo {'EXITOSO' if resultado else 'CON ERRORES'}")
    return resultado


def run_daemon(intervalo_min: int, trigger_pbi: bool):
    """Bucle infinito con sleep entre ciclos."""
    log.info(f"Iniciando daemon — cada {intervalo_min} min")
    while True:
        try:
            run_cycle(trigger_pbi)
        except Exception as e:
            log.error(f"Error no capturado en ciclo: {e}", exc_info=True)
        log.info(f"Próximo ciclo en {intervalo_min} min ...")
        time.sleep(intervalo_min * 60)


if __name__ == "__main__":
    import os
    os.makedirs("logs", exist_ok=True)

    parser = argparse.ArgumentParser(description="Orquestador CECOMSAP BI")
    parser.add_argument("--once",      action="store_true", help="Ejecutar una sola vez")
    parser.add_argument("--daemon",    action="store_true", help="Ejecutar como daemon")
    parser.add_argument("--intervalo", type=int, default=30, help="Minutos entre ciclos (default 30)")
    parser.add_argument("--sin-pbi",   action="store_true", help="No disparar refresco en Power BI")
    args = parser.parse_args()

    trigger_pbi = not args.sin_pbi

    if args.once:
        ok = run_cycle(trigger_pbi)
        sys.exit(0 if ok else 1)
    elif args.daemon:
        run_daemon(args.intervalo, trigger_pbi)
    else:
        parser.print_help()
