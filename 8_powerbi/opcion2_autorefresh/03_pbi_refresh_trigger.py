"""
03_pbi_refresh_trigger.py
Dispara el refresco programático del dataset de Power BI
vía la REST API de Power BI Service.

Requisitos:
  - App registrada en Azure AD con permisos Dataset.ReadWrite.All
  - Variables de entorno configuradas (ver abajo)

Documentación:
  https://learn.microsoft.com/en-us/rest/api/power-bi/datasets/refresh-dataset
"""

import os
import time
import logging
import requests
from datetime import datetime

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO,
                    format="%(asctime)s [%(levelname)s] %(message)s")

# ── Variables de entorno requeridas ───────────────────────────
TENANT_ID    = os.getenv("PBI_TENANT_ID",    "")   # Azure AD tenant
CLIENT_ID    = os.getenv("PBI_CLIENT_ID",    "")   # App registration client ID
CLIENT_SECRET= os.getenv("PBI_CLIENT_SECRET","")   # App registration secret
WORKSPACE_ID = os.getenv("PBI_WORKSPACE_ID", "")   # ID del workspace en Power BI
DATASET_ID   = os.getenv("PBI_DATASET_ID",   "")   # ID del dataset publicado

# ── URLs ──────────────────────────────────────────────────────
TOKEN_URL = f"https://login.microsoftonline.com/{TENANT_ID}/oauth2/v2.0/token"
REFRESH_URL = (
    f"https://api.powerbi.com/v1.0/myorg/"
    f"groups/{WORKSPACE_ID}/datasets/{DATASET_ID}/refreshes"
)
STATUS_URL = REFRESH_URL  # GET al mismo endpoint devuelve el historial


def get_access_token() -> str:
    """Obtiene token OAuth2 de Azure AD (client credentials flow)."""
    resp = requests.post(TOKEN_URL, data={
        "grant_type":    "client_credentials",
        "client_id":     CLIENT_ID,
        "client_secret": CLIENT_SECRET,
        "scope":         "https://analysis.windows.net/powerbi/api/.default",
    })
    resp.raise_for_status()
    token = resp.json()["access_token"]
    log.info("Token obtenido correctamente")
    return token


def trigger_refresh(token: str) -> str:
    """
    Dispara el refresco del dataset.
    Retorna el ID del refresco (requestId).
    """
    headers = {"Authorization": f"Bearer {token}"}
    # Puedes pasar notifyOption: "MailOnFailure" | "NoNotification"
    body = {"notifyOption": "MailOnFailure"}

    resp = requests.post(REFRESH_URL, headers=headers, json=body)

    if resp.status_code == 202:
        request_id = resp.headers.get("RequestId", "desconocido")
        log.info(f"Refresco iniciado — RequestId: {request_id}")
        return request_id
    else:
        log.error(f"Error al disparar refresco: {resp.status_code} {resp.text}")
        resp.raise_for_status()


def get_refresh_status(token: str) -> dict:
    """Obtiene el estado del último refresco."""
    headers = {"Authorization": f"Bearer {token}"}
    resp = requests.get(STATUS_URL, headers=headers, params={"$top": 1})
    resp.raise_for_status()
    items = resp.json().get("value", [])
    return items[0] if items else {}


def wait_for_completion(token: str, timeout_min: int = 20) -> bool:
    """
    Espera hasta que el refresco finalice o timeout.
    Retorna True si completó sin errores.
    """
    deadline = time.time() + timeout_min * 60
    log.info(f"Esperando hasta {timeout_min} min ...")

    while time.time() < deadline:
        time.sleep(30)
        status = get_refresh_status(token)
        estado = status.get("status", "Unknown")
        log.info(f"  Estado actual: {estado}")

        if estado == "Completed":
            log.info("Refresco completado exitosamente")
            return True
        elif estado in ("Failed", "Cancelled", "Disabled"):
            error = status.get("serviceExceptionJson", "sin detalle")
            log.error(f"Refresco falló: {estado} — {error}")
            return False

    log.warning("Timeout esperando refresco")
    return False


def full_refresh_cycle() -> bool:
    """
    Ciclo completo:
    1. Obtener token
    2. Disparar refresco
    3. Esperar resultado
    """
    if not all([TENANT_ID, CLIENT_ID, CLIENT_SECRET, WORKSPACE_ID, DATASET_ID]):
        log.error("Faltan variables de entorno. Configura:")
        log.error("  PBI_TENANT_ID, PBI_CLIENT_ID, PBI_CLIENT_SECRET,")
        log.error("  PBI_WORKSPACE_ID, PBI_DATASET_ID")
        return False

    log.info(f"Iniciando refresco Power BI — {datetime.now():%Y-%m-%d %H:%M:%S}")
    token      = get_access_token()
    request_id = trigger_refresh(token)
    success    = wait_for_completion(token)
    log.info(f"Resultado: {'OK' if success else 'ERROR'}")
    return success


if __name__ == "__main__":
    import sys
    success = full_refresh_cycle()
    sys.exit(0 if success else 1)
