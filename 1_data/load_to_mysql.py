"""
load_to_mysql.py
Carga BD_MARZO26.xlsx → tabla cartera en MySQL (OLTP simulado)
"""

import pandas as pd
import mysql.connector
from mysql.connector import Error
import numpy as np
from datetime import datetime
import os

# ── Config ────────────────────────────────────────────────────
MYSQL_CFG = {
    "host":     os.getenv("MYSQL_HOST",     "localhost"),
    "port":     int(os.getenv("MYSQL_PORT", "3306")),
    "database": os.getenv("MYSQL_DATABASE", "oltp_cecomsap"),
    "user":     os.getenv("MYSQL_ROOT_USER","root"),
    "password": os.getenv("MYSQL_ROOT_PASSWORD", "root1234"),
}
XLSX_PATH = os.getenv(
    "XLSX_PATH",
    os.path.join(os.path.dirname(__file__), "BD MARZO26.xlsx"),
)

# ── Mapeo columnas Excel → BD ──────────────────────────────────
COL_MAP = {
    "COD   ":                          "cod",
    "Titular       ":                  "titular",
    "DI  ":                            "di",
    "TCr   ":                          "tcr",
    "Prod    ":                        "prod",
    "Código Crédito              ":    "codigo_credito",
    " Fecha Desemb             ":      "fecha_desemb",
    "OD  ":                            "od",
    "Monto Crédito             ":      "monto_credito",
    "Plz   ":                          "plazo",
    "Frec    ":                        "frec",
    "Tasa    ":                        "tasa",
    "Saldo Crédito             ":      "saldo_credito",
    "Ultimo Pago           ":          "ultimo_pago",
    "Cuot Atrs         ":              "cuot_atrs",
    "Dias Atrs         ":              "dias_atrs",
    "Capital Atraso              ":    "capital_atraso",
    "Inter.      ":                    "interes",
    "Mora    ":                        "mora",
    "Total     ":                      "total",
    "Cap Venc        ":                "cap_venc",
    "Calif     ":                      "calif",
    "Provis. Cartera               ":  "provision",
    "Teléf     ":                      "telefono",
    "Gestor      ":                    "gestor",
    "Cuota Refer.            ":        "cuota_ref",
    "Cuota Pend          ":            "cuota_pend",
    "FIngreso        ":                "fingreso",
    "SaldAhorro          ":            "sald_ahorro",
    "FNacim      ":                    "fnacim",
    "Gen   ":                          "gen",
    "Aporte      ":                    "aporte",
    "Excp    ":                        "excp",
    "Rurl    ":                        "rurl",
    "Gestor Orig           ":          "gestor_orig",
    "Cuot Pag        ":                "cuot_pag",
    "Analista        ":                "analista",
    "Promotor        ":                "promotor",
    "CC  ":                            "cc",
    "TipoViv       ":                  "tipo_viv",
    "Fndm    ":                        "fndm",
    "Ubig    ":                        "ubig",
    "IntVnc      ":                    "int_vnc",
    "Cntg    ":                        "cntg",
    "FDmbOr      ":                    "fdmb_or",
    "Ley Laboral           ":          "ley_laboral",
    "Centro Laboral              ":    "centro_laboral",
    "Zona Laboral            ":        "zona_laboral",
}

DATE_COLS   = ["fecha_desemb","ultimo_pago","cuota_pend","fingreso","fnacim","fdmb_or"]
INT_COLS    = ["od","plazo","cuot_atrs","dias_atrs","cuot_pag","cc"]
FLOAT_COLS  = ["monto_credito","tasa","saldo_credito","capital_atraso","interes",
               "mora","total","cap_venc","provision","cuota_ref","sald_ahorro",
               "aporte","int_vnc"]
STR_COLS    = ["cod","titular","di","tcr","prod","codigo_credito","frec","calif",
               "telefono","gestor","gen","excp","rurl","gestor_orig","analista",
               "promotor","tipo_viv","fndm","ubig","cntg","ley_laboral",
               "centro_laboral","zona_laboral"]

def clean_df(df: pd.DataFrame) -> pd.DataFrame:
    df = df.rename(columns=COL_MAP)
    df = df[[c for c in COL_MAP.values() if c in df.columns]]
    df = df[df["cod"].notna() & (df["cod"] != "COD")]

    for c in DATE_COLS:
        if c in df.columns:
            df[c] = pd.to_datetime(df[c], errors="coerce").dt.date

    for c in INT_COLS:
        if c in df.columns:
            df[c] = pd.to_numeric(df[c], errors="coerce").fillna(0).astype(int)

    for c in FLOAT_COLS:
        if c in df.columns:
            df[c] = pd.to_numeric(df[c], errors="coerce")

    for c in STR_COLS:
        if c in df.columns:
            df[c] = df[c].astype(str).str.strip().replace("nan", None)

    df["cod"] = df["cod"].astype(str).str.strip()
    return df.replace({np.nan: None})

def build_upsert(cols):
    placeholders = ", ".join(["%s"] * len(cols))
    col_names    = ", ".join(cols)
    updates      = ", ".join([f"{c}=VALUES({c})" for c in cols if c != "cod"])
    return (
        f"INSERT INTO cartera ({col_names}) VALUES ({placeholders}) "
        f"ON DUPLICATE KEY UPDATE {updates}"
    )

def main():
    print(f"[1/3] Leyendo {XLSX_PATH} ...")
    raw = pd.read_excel(XLSX_PATH, header=4)
    df  = clean_df(raw)
    print(f"      {len(df)} filas limpias listas")

    print("[2/3] Conectando a MySQL ...")
    conn = mysql.connector.connect(**MYSQL_CFG)
    cur  = conn.cursor()

    cols = [c for c in COL_MAP.values() if c in df.columns]
    sql  = build_upsert(cols)

    print("[3/3] Insertando en cartera ...")
    batch, total, errors = [], 0, 0
    for _, row in df.iterrows():
        batch.append(tuple(row.get(c) for c in cols))
        if len(batch) == 200:
            try:
                cur.executemany(sql, batch)
                conn.commit()
                total += len(batch)
            except Error as e:
                errors += len(batch)
                print(f"      ERROR en batch: {e}")
            batch = []

    if batch:
        cur.executemany(sql, batch)
        conn.commit()
        total += len(batch)

    cur.close()
    conn.close()
    print(f"Listo: {total} filas insertadas, {errors} errores.")

if __name__ == "__main__":
    main()
