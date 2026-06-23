# Cómo correr todo el proyecto — CECOMSAP BI

> **Versión 100% dockerizada.** Solo necesitas Docker Desktop. No hace falta Python ni dbt en tu PC.
>
> **Comandos para Windows + PowerShell.** En Linux/Mac reemplaza `Get-Content X | docker exec -i …` por `docker exec -i … < X` y `curl.exe` por `curl`.

---

## Requisitos previos

| Herramienta    | Versión mínima | Verificar con            |
| -------------- | --------------- | ------------------------ |
| Docker Desktop | 24+             | `docker --version`       |
| Docker Compose | 2.0+            | `docker compose version` |
| Git            | cualquiera      | `git --version`          |
| Power BI Desktop | (opcional, Windows) | desde la Microsoft Store |

> **Ya no necesitas** Python, pip, ni dbt instalados localmente. Todo corre en contenedores.

---

## Arquitectura de contenedores

### Infraestructura (siempre arriba)

| Contenedor         | Puerto host | Rol               |
| ------------------ | ----------- | ----------------- |
| cecomsap_mysql     | 3306        | Base OLTP         |
| cecomsap_zookeeper | —          | Coordinador Kafka |
| cecomsap_kafka     | 9092        | Message broker (externo); interno `kafka:29092` |
| cecomsap_connect   | 8083        | Debezium (CDC)    |
| cecomsap_postgres  | 5432        | DataWarehouse     |
| cecomsap_kafka_ui  | 8080        | UI opcional       |

### ETL (servicios nuevos)

| Servicio   | Tipo            | Cuándo se levanta                                                |
| ---------- | --------------- | ----------------------------------------------------------------- |
| `loader`   | Job (one-shot)  | `docker compose --profile load run --rm loader`                   |
| `consumer` | Long-running    | `docker compose up -d consumer` (queda corriendo en background)  |
| `dbt`      | Job (on-demand) | `docker compose --profile dbt run --rm dbt run` / `… dbt test`   |

```
[Excel] ─ loader ─▶ MySQL ─ Debezium ─▶ Kafka ─ consumer ─▶ Postgres.raw
                                                                  │
                                                                  ▼
                                                                 dbt
                                                                  │
                                                          ┌───────┴───────┐
                                                      staging          marts
                                                                          │
                                                                          ▼
                                                                vw_*  (Power BI)
```

**Orden de pasos:** Docker → tabla MySQL → loader → Debezium → consumer (en background) → **dbt** → **vistas PBI** → validaciones

---

## Paso 1 — Configurar variables de entorno

```powershell
# En la raíz del proyecto (cecomsap-bi/)
Get-Content .env
```

Contenido por defecto (no hace falta cambiar nada):

```
MYSQL_ROOT_PASSWORD=root1234
MYSQL_DATABASE=oltp_cecomsap
MYSQL_USER=debezium
MYSQL_PASSWORD=debezium123

PG_DATABASE=dw_cecomsap
PG_USER=dw_user
PG_PASSWORD=dw_pass123

KAFKA_BOOTSTRAP=localhost:9092
```

---

## Paso 2 — Levantar la infraestructura

```powershell
docker compose up -d

# Verificar que todos los contenedores están corriendo (deberías ver 6)
docker compose ps
```

Esperar ~30 segundos a que MySQL termine de inicializar:

```powershell
docker compose logs mysql | Select-String "ready for connections"
```

---

## Paso 3 — Crear tabla OLTP en MySQL

```powershell
Get-Content 2_mysql\01_create_oltp_table.sql | docker exec -i cecomsap_mysql mysql -uroot -proot1234 oltp_cecomsap

# Verificar
docker exec cecomsap_mysql mysql -uroot -proot1234 -e "SHOW TABLES IN oltp_cecomsap;"
```

Salida esperada:

```
Tables_in_oltp_cecomsap
cartera
```

---

## Paso 4 — Cargar el Excel a MySQL (loader dockerizado)

> El loader es un contenedor de un solo uso. Lee el Excel desde `1_data/` (montado como volumen), inserta en MySQL y termina.

```powershell
# Construir la imagen (solo la primera vez)
docker compose --profile load build loader

# Ejecutar la carga
docker compose --profile load run --rm loader
```

Salida esperada:

```
[1/3] Leyendo /app/BD MARZO26.xlsx ...
      735 filas limpias listas
[2/3] Conectando a MySQL ...
[3/3] Insertando en cartera ...
Listo: 735 filas insertadas, 0 errores.
```

```powershell
# Verificar la carga
docker exec cecomsap_mysql mysql -uroot -proot1234 -e "SELECT COUNT(*), MIN(fecha_desemb), MAX(fecha_desemb) FROM oltp_cecomsap.cartera;"
```

> 💡 Si tu Excel tiene otro nombre, pasa la variable: `docker compose --profile load run --rm -e XLSX_PATH=/app/OTRO.xlsx loader`

---

## Paso 5 — Registrar el conector Debezium

> Esperar que Kafka Connect esté healthy antes de este paso (`docker compose ps` debe mostrarlo en estado `healthy`).

> En PowerShell, **usa `curl.exe`** — `curl` a secas es alias de `Invoke-WebRequest`.

```powershell
# Verificar que Kafka Connect responde
curl.exe -s http://localhost:8083/

# Registrar el conector MySQL → Kafka
curl.exe -X POST http://localhost:8083/connectors `
  -H "Content-Type: application/json" `
  --data "@3_debezium/connector-config.json"

# Verificar estado del conector (debe decir "RUNNING")
curl.exe -s http://localhost:8083/connectors/cecomsap-mysql-connector/status
```

Salida esperada:

```json
{
  "name": "cecomsap-mysql-connector",
  "connector": { "state": "RUNNING" },
  "tasks": [{ "state": "RUNNING" }]
}
```

```powershell
# Ver los topics creados en Kafka
docker exec cecomsap_kafka kafka-topics --bootstrap-server kafka:29092 --list | Select-String cecomsap
```

Deberías ver: `cecomsap.oltp_cecomsap.cartera`

---

## Paso 6 — Levantar el Consumer (dockerizado, long-running)

> Ya **no** necesitas dejar una terminal abierta — el consumer corre como servicio en background.

```powershell
# Construir la imagen (solo la primera vez)
docker compose build consumer

# Levantarlo (queda en background con restart automático)
docker compose up -d consumer

# Ver los logs del consumer en vivo
docker compose logs -f consumer
# Ctrl+C para dejar de seguir logs (no detiene el contenedor)
```

Salida esperada:

```
cecomsap_consumer  | YYYY-MM-DD [INFO] Conectando a PostgreSQL...
cecomsap_consumer  | YYYY-MM-DD [INFO] Suscribiendo a topic: cecomsap.oltp_cecomsap.cartera
cecomsap_consumer  | YYYY-MM-DD [INFO] Commit: 100 registros — total 100
cecomsap_consumer  | YYYY-MM-DD [INFO] Flush: 35 registros — total 735
```

```powershell
# Verificar que raw.cartera tiene datos
docker exec cecomsap_postgres psql -U dw_user -d dw_cecomsap `
  -c "SELECT COUNT(*), MAX(_cdc_ts) FROM raw.cartera;"
```

---

## Paso 7 — Ejecutar dbt (raw → staging → marts) dockerizado

> dbt corre dentro de un contenedor con la imagen `cecomsap-bi-dbt`. El proyecto en `6_dbt/` se monta como volumen, así que los cambios en los modelos se reflejan al instante.
>
> **IMPORTANTE:** dbt debe correr antes del paso 8 (vistas Power BI), porque las vistas dependen de `marts.fact_cartera` que dbt crea.

```powershell
# Construir la imagen (solo la primera vez)
docker compose --profile dbt build dbt

# Verificar conexión a PostgreSQL
docker compose --profile dbt run --rm dbt debug

# Instalar dependencias del proyecto dbt (si las hay)
docker compose --profile dbt run --rm dbt deps

# Ejecutar todos los modelos
docker compose --profile dbt run --rm dbt run

# Tests de calidad
docker compose --profile dbt run --rm dbt test
```

Deberías terminar con `PASS=7 WARN=0 ERROR=0` y estas tablas/vistas creadas:

```
staging.stg_cartera                   (view)
marts.dim_calificacion / dim_cliente / dim_fecha / dim_gestor / dim_producto   (tables)
marts.fact_cartera                    (incremental table)
```

> 💡 Atajo: define una función en tu PowerShell profile:
> ```powershell
> function dbt-cli { docker compose --profile dbt run --rm dbt @args }
> # Después: dbt-cli run, dbt-cli test, dbt-cli debug, etc.
> ```

---

## Paso 8 — Crear vistas para Power BI

> Requiere que `marts.fact_cartera` ya exista (paso 7 completado).

```powershell
Get-Content 8_powerbi\opcion2_autorefresh\01_pg_views_para_pbi.sql | docker exec -i cecomsap_postgres psql -U dw_user -d dw_cecomsap

# Verificar vistas creadas
docker exec cecomsap_postgres psql -U dw_user -d dw_cecomsap -c "\dv marts.*"
```

Deberías ver:

```
marts.vw_cartera_pbi
marts.vw_kpis_resumen
marts.vw_rendimiento_gestor
```

---

## Paso 9 — Verificar el DataMart completo

```powershell
Get-Content 7_validacion\01_check_oltp_vs_raw.sql      | docker exec -i cecomsap_postgres psql -U dw_user -d dw_cecomsap
Get-Content 7_validacion\02_check_raw_vs_staging.sql   | docker exec -i cecomsap_postgres psql -U dw_user -d dw_cecomsap
Get-Content 7_validacion\03_check_staging_vs_marts.sql | docker exec -i cecomsap_postgres psql -U dw_user -d dw_cecomsap
Get-Content 7_validacion\04_kpis_analiticos.sql        | docker exec -i cecomsap_postgres psql -U dw_user -d dw_cecomsap
```

Resultado esperado del último script (KPIs):

```
 total_creditos | saldo_vigente_total | cartera_en_mora | indice_morosidad_pct
----------------+--------------------+-----------------+---------------------
            735 |        28,412,xxx  |      xx,xxx     |               65.xx
```

---

## Paso 10 — Conectar Power BI Desktop

> Power BI Desktop sí se instala en tu Windows (no se puede dockerizar). Se conecta al PostgreSQL del contenedor vía `localhost:5432`.

1. Abrir **Power BI Desktop**
2. `Obtener datos` → `Base de datos` → **PostgreSQL**
3. Configurar la conexión:

```
Servidor:         localhost:5432
Base de datos:    dw_cecomsap
Modo:             Importar
```

4. Seleccionar estas tablas del schema `marts`:

```
✓ vw_cartera_pbi          (tabla principal — 735 filas con todo)
✓ vw_kpis_resumen         (tarjetas de KPI)
✓ vw_rendimiento_gestor   (tabla de gestores)
✓ dim_calificacion        (para segmentadores)
✓ dim_fecha               (filtros temporales)
```

5. En el modelo de datos, crear relaciones:

| Desde            | Campo              | Hacia              | Campo          |
| ---------------- | ------------------ | ------------------ | -------------- |
| `vw_cartera_pbi` | `calificacion`     | `dim_calificacion` | `calificacion` |
| `vw_cartera_pbi` | `fecha_desembolso` | `dim_fecha`        | `full_date`    |

6. Importar las medidas DAX desde [8_powerbi/medidas_dax.md](8_powerbi/medidas_dax.md)

---

## Paso 11 — Publicar en Power BI Service

```
Power BI Desktop
→ Archivo → Publicar → Power BI Service
→ Seleccionar workspace: "CECOMSAP-BI" (créalo si no existe)
→ Publicar
```

---

## Paso 12 — Instalar el Gateway (Windows, fuera de Docker)

> Necesario para que Power BI Service acceda al PostgreSQL local.

```powershell
# En PowerShell como Administrador
.\8_powerbi\opcion2_autorefresh\05_instalar_gateway.ps1
```

Luego en **Power BI Service** (`app.powerbi.com`):

```
Settings (⚙) → Manage connections and gateways
→ New → On-premises
  Gateway cluster:  CECOMSAP-Gateway
  Connection type:  PostgreSQL
  Server:           localhost
  Database:         dw_cecomsap
  Username:         pbi_reader
  Password:         pbi_readonly_2026
→ Create
```

---

## Paso 13 — Configurar refresh automático en Power BI Service

```
Workspace CECOMSAP-BI
→ Dataset: cecomsap_cartera → ⋯ → Settings

Pestaña "Gateway connection":
  → Seleccionar CECOMSAP-Gateway → Apply

Pestaña "Scheduled refresh":
  → Keep your data up to date: ON
  → Refresh frequency: Daily
  → Time zone: (UTC-05:00) Lima
  → Add time: 06:00 | 12:00 | 18:00
  → Failure notifications: ON
  → Apply
```

---

## Paso 14 — Activar el orquestador (dbt periódico)

El orquestador `04_orquestador.py` necesita acceso a la API de Power BI desde Windows, así que se queda fuera de Docker. Dos formas de correrlo periódicamente:

### Opción A — Trigger dbt periódico desde Docker (sin orquestador local)

Crea una tarea programada de Windows que dispare `dbt run` cada 30 min usando el contenedor:

```powershell
$action  = New-ScheduledTaskAction `
  -Execute "docker" `
  -Argument "compose --profile dbt run --rm dbt run" `
  -WorkingDirectory "C:\Nueva carpeta (20)\cecomsap-bi"

$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) `
  -RepetitionInterval (New-TimeSpan -Minutes 30)

Register-ScheduledTask -TaskName "CECOMSAP_dbt" -Action $action -Trigger $trigger
```

### Opción B — Orquestador completo (con auto-refresh PBI)

Necesita Python local porque dispara la API REST de Power BI:

```powershell
py -3.12 -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install requests msal psycopg2-binary
python 8_powerbi\opcion2_autorefresh\04_orquestador.py --daemon --intervalo 30
```

---

## Resumen — qué queda corriendo al final

```
docker compose up -d              ← infraestructura (6 contenedores) + consumer
                                    siempre en background

Task Scheduler "CECOMSAP_dbt"     ← dispara dbt cada 30 min (opcional)
```

Ya no se necesitan terminales abiertas para nada.

---

## Verificación final rápida

```powershell
# 1. Docker: todo corriendo
docker compose ps

# 2. Consumer: raw.cartera con datos frescos
docker exec cecomsap_postgres psql -U dw_user -d dw_cecomsap `
  -c "SELECT COUNT(*), NOW()-MAX(_cdc_ts) AS antiguedad FROM raw.cartera;"

# 3. dbt: marts con datos
docker exec cecomsap_postgres psql -U dw_user -d dw_cecomsap `
  -c "SELECT COUNT(*), MAX(cdc_timestamp) FROM marts.fact_cartera;"

# 4. Vistas: Power BI puede leer
docker exec cecomsap_postgres psql -U pbi_reader -d dw_cecomsap `
  -c "SELECT total_creditos, indice_morosidad_pct FROM marts.vw_kpis_resumen;"

# 5. Log de refrescos
docker exec cecomsap_postgres psql -U dw_user -d dw_cecomsap `
  -c "SELECT fuente, estado, ts FROM marts.refresh_log ORDER BY ts DESC LIMIT 5;"
```

---

## Troubleshooting rápido

| Síntoma                                          | Causa                            | Solución                                              |
| ------------------------------------------------ | -------------------------------- | ----------------------------------------------------- |
| `unable to get image … npipe`                   | Docker Desktop no arrancado      | Abrir Docker Desktop y esperar el ✓ verde            |
| `docker compose ps` muestra Exit                 | Contenedor caído                | `docker compose up -d` y `docker compose logs <svc>` |
| `loader: FileNotFoundError BD MARZO26.xlsx`      | Excel renombrado/movido          | Pasa `-e XLSX_PATH=/app/<tu_archivo>.xlsx`            |
| `consumer: KafkaError no broker available`       | Kafka aún no listo              | `docker compose restart consumer` después de 30s     |
| `dbt debug: could not translate host postgres`   | dbt corrido fuera del compose    | Usar `docker compose --profile dbt run --rm dbt …`   |
| `< file.sql` "operador no reconocido"            | Sintaxis bash en PowerShell      | Usar `Get-Content file.sql \| docker exec -i …`       |
| `curl: param error`                              | PowerShell aliasa `curl`         | Usar `curl.exe`                                       |
| Debezium dice `FAILED`                           | MySQL binlog desactivado         | Verificar `my.cnf` y reiniciar MySQL                  |
| Power BI no ve el Gateway                        | PC apagada / Gateway offline     | Encender PC del servidor                              |

---

## Comandos útiles

```powershell
# Reconstruir una imagen después de cambiar código
docker compose build consumer        # o loader, o dbt

# Re-correr el loader (porque viste un dato mal)
docker compose --profile load run --rm loader

# Ver logs de un servicio long-running
docker compose logs -f consumer

# Entrar a un contenedor para debug
docker exec -it cecomsap_postgres psql -U dw_user -d dw_cecomsap
docker exec -it cecomsap_mysql mysql -uroot -proot1234 oltp_cecomsap
docker compose --profile dbt run --rm --entrypoint /bin/bash dbt    # shell dentro del dbt

# Reset total (borra todos los datos)
docker compose --profile load --profile dbt down -v
```

---

## Apagar el proyecto correctamente

```powershell
# Detener todo (conserva los datos)
docker compose down

# Detener Y borrar datos
docker compose --profile load --profile dbt down -v
```

---

## Contacto de tablas y credenciales

| Componente       | Host (desde Windows) | Host (entre contenedores) | Puerto      | Usuario         | Base de datos |
| ---------------- | -------------------- | -------------------------- | ----------- | --------------- | ------------- |
| MySQL OLTP       | localhost            | mysql                      | 3306        | root / debezium | oltp_cecomsap |
| PostgreSQL DW    | localhost            | postgres                   | 5432        | dw_user         | dw_cecomsap   |
| PostgreSQL (PBI) | localhost            | postgres                   | 5432        | pbi_reader      | dw_cecomsap   |
| Kafka            | localhost            | kafka                      | 9092 / 29092 | —              | —            |
| Kafka Connect    | localhost            | kafka-connect              | 8083        | —              | —            |
| Kafka UI         | localhost            | —                         | 8080        | —              | —            |
