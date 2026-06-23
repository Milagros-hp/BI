# Proyecto BI — Cartera de Créditos CECOMSAP

**Cooperativa de Ahorro y Crédito CECOMSAP Limitada**  
**Corte:** 31/03/2026 · **737 créditos** · **Pipeline:** MySQL → Kafka → Consumer → PostgreSQL → dbt → Power BI

## Pipeline
```
BD_MARZO26.xlsx → MySQL (OLTP) → Debezium (CDC) → Kafka → Consumer (Python) → PostgreSQL raw → dbt staging → dbt marts → Power BI
```

## Levantamiento rápido
```bash
# 1. Variables de entorno
cp .env.example .env

# 2. Levantar stack completo
docker-compose up -d

# 3. Cargar data Excel a MySQL
pip install -r 4_consumer/requirements.txt
python 1_data/load_to_mysql.py

# 4. Registrar conector Debezium
curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d @3_debezium/connector-config.json

# 5. Iniciar consumer
python 4_consumer/consumer.py

# 6. Ejecutar dbt
cd 6_dbt
dbt deps
dbt run
dbt test
```

## Estructura de capas PostgreSQL
| Schema | Capa | Descripción |
|--------|------|-------------|
| `raw`     | Bronze | Réplica exacta desde Kafka consumer |
| `staging` | Silver | Limpieza y estandarización (dbt) |
| `marts`   | Gold   | Dimensiones + fact_cartera (dbt) |

## Modelo dimensional
- `dim_fecha` · `dim_producto` · `dim_cliente` · `dim_gestor` · `dim_calificacion`
- `fact_cartera` — grano: un crédito al corte 31/03/2026
