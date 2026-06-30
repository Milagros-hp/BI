# COOPAC CECOMSAP — Business Intelligence

**Unidad 3 — Sistema de Inteligencia de Negocios — Cartera de Créditos**  
Universidad Peruana Unión · Escuela Profesional de Ingeniería de Sistemas · 2026-I

---

## Descripción del Proyecto

Solución BI end-to-end construida para la **Cooperativa de Ahorro y Crédito CECOMSAP Limitada** (San Román, Puno). Cubre el ciclo completo: desde la base de datos transaccional hasta el dashboard en Power BI.

| Campo | Detalle |
|---|---|
| Proceso de negocio | Gestión de cartera de créditos al corte 31/03/2026 — 737 créditos |
| Fuente transaccional | MySQL 8.0 (oltp_cecomsap) — contenedor Docker |
| Repositorio | [github.com/Milagros-hp/BI](https://github.com/Milagros-hp/BI.git) |

## Equipo

| Integrante | Rol |
|---|---|
| Arce Apaza Bisleyn de la Flor | Integrante 1 |
| Huanca Pacco Luz Milagros | Integrante 2 |

**Docente:** Mg. Abel Ángel Sullon Macalupu

---

## Pipeline

```
BD MARZO26.xlsx → MySQL OLTP → Debezium CDC → Kafka
    → Consumer Python → PostgreSQL raw (Bronze)
    → dbt staging (Silver) → dbt marts (Gold)
    → Power BI
```

## KPIs Implementados

| # | KPI | Semáforo Riesgo | Semáforo Alerta | Semáforo Saludable |
|---|---|---|---|---|
| 1 | Saldo Vigente Total | — | — | — |
| 2 | Capital en Mora | — | — | — |
| 3 | Índice de Morosidad % | > 8% | 5–8% | < 5% |
| 4 | Provisión Total | — | — | — |
| 5 | Cobertura de Provisión % | < 80% | 80–100% | > 100% |
| 6 | % Cartera en Riesgo | > 15% | 8–15% | < 8% |

## Resultado de Validación

> Saldo Vigente Total en `marts.fact_cartera` = **S/ 12,586,209.81**  
> Mismo valor en Power BI. **Diferencia = S/ 0.00 ✓**
