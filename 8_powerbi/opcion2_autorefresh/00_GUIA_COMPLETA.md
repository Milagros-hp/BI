# Opción 2 — Auto-Refresh Power BI · Guía completa

## Arquitectura de la solución

```
MySQL (OLTP)
    ↓  Debezium CDC
Kafka topic: cecomsap.oltp_cecomsap.cartera
    ↓  consumer.py (siempre corriendo)
PostgreSQL raw.cartera
    ↓  dbt run (cada 30 min vía orquestador)
PostgreSQL marts.fact_cartera + vistas vw_*
    ↓  On-premises Data Gateway
Power BI Service (actualización programada)
    ↓
Dashboard Power BI (usuarios finales)
```

---

## Paso 1 · Preparar PostgreSQL

```bash
# Conectar a PostgreSQL
docker exec -it cecomsap_postgres psql -U dw_user -d dw_cecomsap

# Ejecutar el script de vistas y usuario de solo lectura
\i /path/to/8_powerbi/opcion2_autorefresh/01_pg_views_para_pbi.sql

# Verificar vistas creadas
\dv marts.*
```

Deberías ver:
```
marts.vw_cartera_pbi
marts.vw_kpis_resumen
marts.vw_rendimiento_gestor
marts.refresh_log
```

---

## Paso 2 · Instalar On-premises Data Gateway

### En Windows (recomendado para Power BI)
```powershell
# Ejecutar como Administrador
.\05_instalar_gateway.ps1
```

### Manual
1. Descargar desde: https://go.microsoft.com/fwlink/?LinkId=2116849
2. Instalar → "On-premises data gateway (standard mode)"
3. Iniciar sesión con tu cuenta de Power BI / Microsoft 365
4. Nombre del gateway: `CECOMSAP-Gateway`
5. Guardar la Recovery Key en lugar seguro

---

## Paso 3 · Configurar fuente de datos en Gateway

En **Power BI Service** (app.powerbi.com):

```
Settings (⚙) → Manage connections and gateways
→ New connection → On-premises
→ Gateway: CECOMSAP-Gateway
→ Connection type: PostgreSQL

  Server:          localhost        (o IP del servidor)
  Database:        dw_cecomsap
  Authentication:  Basic
  Username:        pbi_reader
  Password:        pbi_readonly_2026

→ Create
```

---

## Paso 4 · Conectar Power BI Desktop

```
Obtener datos → Base de datos → PostgreSQL
  Servidor:         localhost:5432
  Base de datos:    dw_cecomsap
  Modo de conexión: Importar

Seleccionar tablas:
  ✓ marts.vw_cartera_pbi        ← tabla principal
  ✓ marts.vw_kpis_resumen       ← tarjetas KPI
  ✓ marts.vw_rendimiento_gestor ← tabla gestores
  ✓ marts.dim_calificacion      ← para segmentadores
  ✓ marts.dim_fecha             ← filtros por fecha
```

**No seleccionar** `raw.*` ni `staging.*` — Power BI solo necesita `marts.*`.

---

## Paso 5 · Publicar en Power BI Service

```
Power BI Desktop → Archivo → Publicar → Power BI Service
→ Seleccionar workspace: CECOMSAP-BI (o crear uno nuevo)
→ Publicar
```

---

## Paso 6 · Configurar auto-refresh

En Power BI Service:
```
Workspace CECOMSAP-BI
→ Dataset: cecomsap_cartera
→ ⋯ (tres puntos) → Settings

Tab "Gateway connection":
  Gateway: CECOMSAP-Gateway
  Map → dw_cecomsap → pbi_reader

Tab "Scheduled refresh":
  Keep your data up to date: ON
  Refresh frequency: Daily (o cada hora con licencia Premium)
  Time zone: (UTC-05:00) Bogotá, Lima, Quito
  Times: 06:00, 08:00, 12:00, 18:00

Failure notifications: Send email to dataset owner → ON
```

---

## Paso 7 · Activar el orquestador Python

El orquestador se encarga de correr dbt antes de que Power BI refresque.

```bash
# Instalar dependencias
pip install -r 4_consumer/requirements.txt

# Probar una vez
python 8_powerbi/opcion2_autorefresh/04_orquestador.py --once --sin-pbi

# Correr como daemon (en producción)
python 8_powerbi/opcion2_autorefresh/04_orquestador.py --daemon --intervalo 30
```

### En Linux (crontab recomendado)
```bash
crontab -e

# Correr cada 30 minutos — dbt run + verificación
*/30 * * * * cd /ruta/cecomsap-bi && python 8_powerbi/opcion2_autorefresh/02_monitor_frescura.py >> logs/monitor.log 2>&1
```

### En Windows (Task Scheduler)
```
Inicio → Programador de tareas → Crear tarea básica
  Nombre: CECOMSAP dbt Refresh
  Desencadenador: Diariamente, repetir cada 30 minutos
  Acción: Iniciar programa
    Programa: python
    Argumentos: 8_powerbi/opcion2_autorefresh/04_orquestador.py --once
    Iniciar en: C:\ruta\cecomsap-bi
```

---

## Paso 8 · Configurar variables de entorno para la API

Solo si quieres que Python también dispare el refresco de Power BI (opcional):

```bash
# .env (agregar estas líneas)
PBI_TENANT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
PBI_CLIENT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
PBI_CLIENT_SECRET=tu-secreto-azure-ad
PBI_WORKSPACE_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
PBI_DATASET_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

Para obtener los IDs de Azure:
1. portal.azure.com → Azure Active Directory → App registrations → New registration
2. Nombre: `cecomsap-bi-refresh`
3. API permissions → Add → Power BI Service → Dataset.ReadWrite.All
4. Certificates & secrets → New client secret → copiar valor

---

## Flujo de tiempos recomendado

```
00:00  Consumer Kafka siempre activo → raw.cartera actualizado
05:55  Orquestador: dbt run + dbt test → marts actualizados
06:00  Power BI Service dispara refresco automático
06:05  Dashboard listo con datos frescos para el equipo

11:55  Orquestador: dbt run
12:00  Power BI refresca

17:55  Orquestador: dbt run
18:00  Power BI refresca
```

---

## Verificar que todo funciona

```sql
-- Ver log de refrescos (en PostgreSQL)
SELECT fuente, registros, duracion_seg, estado, ts
FROM marts.refresh_log
ORDER BY ts DESC
LIMIT 20;

-- Ver última actualización de los marts
SELECT MAX(cdc_timestamp) AS ultima_actualizacion
FROM marts.fact_cartera;
```

En Power BI Service:
```
Dataset → Refresh history → ver lista de refrescos con estado
```

---

## Troubleshooting

| Problema | Causa probable | Solución |
|----------|---------------|----------|
| Gateway offline | PC apagada | Dejar PC servidor encendida |
| Error "credentials" | Password cambiada | Actualizar en Gateway settings |
| dbt falla | PostgreSQL caído | `docker-compose up -d postgres` |
| Refresco lento | Muchas filas | Usar DirectQuery en lugar de Import |
| Power BI dice "Gateway not found" | Gateway no registrado | Re-registrar con `05_instalar_gateway.ps1` |
